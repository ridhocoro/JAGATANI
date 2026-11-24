/*
  =============================================================================
  JagaTani ESP32 Firmware: Aktuator Pompa Irigasi & Failsafe Controller (A-01)
  =============================================================================
  Fitur & Failsafe:
  1. Boot-time Safety: Relay dijamin OFF saat boot/restart (H-03).
  2. Local Timer Failsafe: Pompa mati otomatis oleh ESP32 setelah durasi habis,
     meskipun koneksi WiFi/MQTT terputus (H-01, H-02).
  3. Emergency Stop: Perintah "off" mematikan relay dalam < 1 detik (H-04).
  4. Watchdog Backend: Pompa mati jika backend tidak mengirim heartbeat > 5 menit.
  5. Telemetri Real-time: Menerbitkan status ke broker per 60 detik atau saat ada perubahan.

  Topik MQTT:
  - Subscribe: jagatani/aktuator/pompa/<ZONA_ID>
  - Publish  : jagatani/aktuator/status/<ZONA_ID>
  =============================================================================
*/

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// ---------------------------------------------------------------------------
// 1. KONFIGURASI JARINGAN & BROKER (Sesuaikan dengan kredensial setempat)
// ---------------------------------------------------------------------------
const char* WIFI_SSID     = "JAGATANI_WIFI";
const char* WIFI_PASSWORD = "PasswordRahasia";

const char* MQTT_BROKER   = "broker.emqx.io";
const int   MQTT_PORT     = 1883;
const char* MQTT_USER     = "";
const char* MQTT_PASS     = "";

// ID Zona yang dikontrol ESP32 ini (contoh: zone_a, zone_b, zone_c)
const char* ZONA_ID       = "zone_a";

// ---------------------------------------------------------------------------
// 2. PIN HARDWARE & SAFETY LEVEL
// ---------------------------------------------------------------------------
// Pin Relay Pompa (Gunakan optocoupler terisolasi, catu daya terpisah dari ESP32)
const int RELAY_PIN       = 26; 

// Kebanyakan modul relay Arduino/ESP32 bersifat ACTIVE-LOW (LOW = Relay ON)
const bool RELAY_ACTIVE_LOW = true;

// Waktu maksimal pompa hidup tanpa sinyal keep-alive backend (5 menit)
const unsigned long BACKEND_TIMEOUT_MS = 300000UL; 

// ---------------------------------------------------------------------------
// 3. VARIABEL STATE SISTEM & FAILSAFE TIMER
// ---------------------------------------------------------------------------
WiFiClient espClient;
PubSubClient mqttClient(espClient);

char topicSub[64];
char topicPub[64];

bool pumpIsActive = false;
unsigned long pumpStartTime = 0;
unsigned long pumpDurationMs = 0;
char currentCommandId[40] = "";

unsigned long lastStatusPublishTime = 0;
const unsigned long STATUS_INTERVAL_MS = 60000UL; // 60 detik

unsigned long lastBackendKeepaliveTime = 0;

// ---------------------------------------------------------------------------
// 4. HELPER FUNGSI KONTROL RELAY
// ---------------------------------------------------------------------------
void setRelayState(bool turnOn) {
  if (turnOn) {
    digitalWrite(RELAY_PIN, RELAY_ACTIVE_LOW ? LOW : HIGH);
    pumpIsActive = true;
    Serial.println("[RELAY] POMPA AKTIF (ON)");
  } else {
    digitalWrite(RELAY_PIN, RELAY_ACTIVE_LOW ? HIGH : LOW);
    pumpIsActive = false;
    pumpDurationMs = 0;
    Serial.println("[RELAY] POMPA NON-AKTIF (OFF)");
  }
}

// ---------------------------------------------------------------------------
// 5. HELPER TELEMETRI STATUS KE MQTT
// ---------------------------------------------------------------------------
void publishStatus() {
  unsigned long remainingSec = 0;
  if (pumpIsActive) {
    unsigned long elapsed = millis() - pumpStartTime;
    if (elapsed < pumpDurationMs) {
      remainingSec = (pumpDurationMs - elapsed) / 1000UL;
    }
  }

  StaticJsonDocument<200> doc;
  doc["pompa"] = pumpIsActive ? "on" : "off";
  doc["id_perintah"] = currentCommandId[0] != '\0' ? currentCommandId : "idle";
  doc["sisa_detik"] = remainingSec;

  char buffer[256];
  serializeJson(doc, buffer);

  if (mqttClient.connected()) {
    mqttClient.publish(topicPub, buffer);
    Serial.print("[MQTT STATUS PUBLISHED] ");
    Serial.println(buffer);
  }
}

// ---------------------------------------------------------------------------
// 6. CALLBACK PEMROSES PESAN PERINTAH MQTT
// ---------------------------------------------------------------------------
void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  lastBackendKeepaliveTime = millis(); // Refresh backend watchdog

  char jsonPayload[512];
  if (length >= sizeof(jsonPayload)) {
    Serial.println("[MQTT ERROR] Payload terlalu besar");
    return;
  }
  memcpy(jsonPayload, payload, length);
  jsonPayload[length] = '\0';

  Serial.print("[MQTT RCVD] ");
  Serial.println(jsonPayload);

  StaticJsonDocument<512> doc;
  DeserializationError err = deserializeJson(doc, jsonPayload);
  if (err) {
    Serial.print("[JSON ERROR] Parsing gagal: ");
    Serial.println(err.c_str());
    return;
  }

  const char* aksi = doc["aksi"] | "";
  const char* idCmd = doc["id_perintah"] | "";

  if (strcmp(aksi, "on") == 0) {
    long durasiDetik = doc["durasi_detik"] | 0;

    // Batas pengaman hardware: Klem durasi lokal maksimal 15 menit (900 detik)
    if (durasiDetik > 900) durasiDetik = 900;
    if (durasiDetik < 5)   durasiDetik = 5;

    strncpy(currentCommandId, idCmd, sizeof(currentCommandId) - 1);
    pumpDurationMs = (unsigned long)durasiDetik * 1000UL;
    pumpStartTime = millis();

    setRelayState(true);
    publishStatus(); // Publikasikan status segera

  } else if (strcmp(aksi, "off") == 0) {
    // Skenario H-04: Emergency off dalam < 1 detik
    setRelayState(false);
    strncpy(currentCommandId, idCmd, sizeof(currentCommandId) - 1);
    publishStatus(); // Publikasikan status segera
  }
}

// ---------------------------------------------------------------------------
// 7. SETUP & INITIALIZATION
// ---------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n--- JagaTani ESP32 Aktuator Booting ---");

  // Format topik
  snprintf(topicSub, sizeof(topicSub), "jagatani/aktuator/pompa/%s", ZONA_ID);
  snprintf(topicPub, sizeof(topicPub), "jagatani/aktuator/status/%s", ZONA_ID);

  // Skenario H-03: Relay dimulai dalam kondisi MATI saat boot
  pinMode(RELAY_PIN, OUTPUT);
  setRelayState(false);

  // Setup WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("[WIFI] Menghubungkan ke ");
  Serial.println(WIFI_SSID);

  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(onMqttMessage);

  lastBackendKeepaliveTime = millis();
}

// ---------------------------------------------------------------------------
// 8. MQTT RECONNECT HANDLER
// ---------------------------------------------------------------------------
void reconnectMqtt() {
  if (mqttClient.connected()) return;

  Serial.print("[MQTT] Menghubungkan ke broker...");
  String clientId = "JagaTani_ESP32_" + String(ZONA_ID) + "_" + String(random(0xffff), HEX);

  if (mqttClient.connect(clientId.c_str(), MQTT_USER, MQTT_PASS)) {
    Serial.println(" Terhubung!");
    mqttClient.subscribe(topicSub);
    Serial.print("[MQTT] Subscribed ke ");
    Serial.println(topicSub);
    publishStatus();
  } else {
    Serial.print(" Gagal, rc=");
    Serial.println(mqttClient.state());
  }
}

// ---------------------------------------------------------------------------
// 9. MAIN LOOP DENGAN NON-BLOCKING FAILSAFE
// ---------------------------------------------------------------------------
void loop() {
  unsigned long now = millis();

  // -------------------------------------------------------------------------
  // FAILSAFE #1: Timer Lokal Habis (H-01 & H-02)
  // Berjalan di tingkat firmware tanpa bergantung pada koneksi jaringan!
  // -------------------------------------------------------------------------
  if (pumpIsActive) {
    if (now - pumpStartTime >= pumpDurationMs) {
      Serial.println("[FAILSAFE LOCAL TIMER] Durasi siram habis. Mematikan pompa...");
      setRelayState(false);
      publishStatus();
    }
  }

  // -------------------------------------------------------------------------
  // FAILSAFE #2: Watchdog Backend Timeout
  // Jika pompa aktif tetapi backend tidak mengirim keepalive > 5 menit, matikan.
  // -------------------------------------------------------------------------
  if (pumpIsActive) {
    if (now - lastBackendKeepaliveTime >= BACKEND_TIMEOUT_MS) {
      Serial.println("[FAILSAFE WATCHDOG] Backend heartbeat hilang > 5 menit. Mematikan pompa...");
      setRelayState(false);
      publishStatus();
    }
  }

  // -------------------------------------------------------------------------
  // KONEKSI & MQTT POLLING
  // -------------------------------------------------------------------------
  if (WiFi.status() == WL_CONNECTED) {
    if (!mqttClient.connected()) {
      static unsigned long lastMqttRetry = 0;
      if (now - lastMqttRetry > 5000) {
        lastMqttRetry = now;
        reconnectMqtt();
      }
    } else {
      mqttClient.loop();
    }
  }

  // -------------------------------------------------------------------------
  // TELEMETRI BERKALA (Setiap 60 detik)
  // -------------------------------------------------------------------------
  if (now - lastStatusPublishTime >= STATUS_INTERVAL_MS) {
    lastStatusPublishTime = now;
    publishStatus();
  }

  delay(10); // Memberikan yield time ke OS ESP32
}
