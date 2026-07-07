%populate {
    object WiFi {
        object Radio {
{% for ( let Radio in BD.Radios ) : if (Radio.OperatingFrequency == "6GHz") : %}
            object '{{Radio.Alias}}' {
                object ScanConfig {
                    parameter OnlyScanPscChannels = 0;
                }
            }
{% endif; endfor; %}
        }
        object EndPoint {
{% for ( let Itf in BD.Interfaces ) : if ( BDfn.isInterfaceWirelessEp(Itf.Name) ) : %}
            object '{{Itf.Alias}}' {
                parameter ReconnectInterval = 60;
                parameter ReconnectDelay = 60;
            }
{% endif; endfor; %}
        }
    }
}
