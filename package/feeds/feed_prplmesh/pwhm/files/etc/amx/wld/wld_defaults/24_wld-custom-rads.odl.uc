%populate {
    object WiFi {
        object Radio {
{% for ( let Radio in BD.Radios ) : %}
{% if (Radio.OperatingFrequency == "2.4GHz") : %}
            object '{{Radio.Alias}}' {
                parameter 'RegulatoryDomain' = "US";
                object ChannelMgt {
                    parameter AcsBootChannel = 1;
                }
            }
{% elif (Radio.OperatingFrequency == "5GHz") : %}
            object '{{Radio.Alias}}' {
                parameter 'RegulatoryDomain' = "US";
                object ChannelMgt {
                    parameter AcsBootChannel = 36;
                }
            }
{% elif (Radio.OperatingFrequency == "6GHz") : %}
            object '{{Radio.Alias}}' {
                parameter 'RegulatoryDomain' = "US";
                object ChannelMgt {
                    parameter AcsBootChannel = 37;
                }
            }
{% endif; endfor; %}
        }
    }
}
