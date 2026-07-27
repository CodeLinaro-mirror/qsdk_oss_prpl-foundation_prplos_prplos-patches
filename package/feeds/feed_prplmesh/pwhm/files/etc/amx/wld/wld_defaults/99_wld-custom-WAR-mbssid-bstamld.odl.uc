%populate {
    object WiFi {
        object Radio {
{% for ( let Radio in BD.Radios ) : if (Radio.OperatingFrequency == "6GHz") : %}
            object '{{Radio.Alias}}' {
                object IEEE80211ax {
                    parameter MBSSIDAdvertisementMode = "Auto";
                }
            }
{% endif; endfor; %}
        }
    }
}
