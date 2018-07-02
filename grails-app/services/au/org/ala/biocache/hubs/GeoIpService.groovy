/*
 * Copyright (C) 2014 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */
package au.org.ala.biocache.hubs

import com.maxmind.db.CHMCache
import com.maxmind.geoip2.DatabaseReader
import com.maxmind.geoip2.exception.AddressNotFoundException
import com.maxmind.geoip2.model.CityResponse
import com.maxmind.geoip2.record.Location
import groovy.util.logging.Slf4j

import javax.annotation.PostConstruct
import javax.servlet.http.HttpServletRequest

/**
 * Provides methods to access MaxMind GeoIP2 API (http://maxmind.github.io/GeoIP2-java/)
 * Some code for getIpAddress has been taken from https://github.com/donbeave/grails-geoip/
 * Download City DB from https://dev.maxmind.com/geoip/geoip2/geolite2/

 * DB Download is automated and installed to grailsApplication.config.geopip.database.path as part of
 * ala-install ansible playbooks and roles (https://github.com/AtlasOfLivingAustralia/ala-install/blob/82d2f13e462680c20f805e0f5e061d21fbe8a352/ansible/roles/biocache-hub/tasks/main.yml#L137)
 * @author Javier Molina
 */
@Slf4j
class GeoIpService {
    DatabaseReader reader

    def grailsApplication

    @PostConstruct
    void init() {
        //
        // Path to "GeoIP2-City.mmdb"
        String filePath = grailsApplication.config.geopip.database.path

        // A File object pointing to your GeoIP2 or GeoLite2 database
        File fileDatabase = new File(filePath)

        if(!fileDatabase.exists() || !fileDatabase.canRead()) {
            log.warn("GeoIP Database file [${filePath}] does not exist or can't be read. GeoIpservice will be bypassed.")
            return
        }

        // This creates the DatabaseReader object, which should be reused across
        // lookups.

        try {
            reader = new DatabaseReader.Builder(fileDatabase).withCache(new CHMCache()).build()
            log.info("Loaded GeoIP Database file  from file [${filePath}].")
        } catch (Exception ex) {
            log.error("Unable to open GeoIp Database [${filePath}]. GeoIpservice will be bypassed.", ex)
        }
    }

    static List<String> ipHeaders = ['X-Real-IP',
                                     'Client-IP',
                                     'X-Forwarded-For',
                                     'Proxy-Client-IP',
                                     'WL-Proxy-Client-IP',
                                     'rlnclientipaddr']

    private InetAddress getIpAddress(HttpServletRequest  request) {
        String unknown = 'unknown'
        String inetAddressStr = unknown

        ipHeaders.each { header ->
            if (!inetAddressStr || unknown.equalsIgnoreCase(inetAddressStr))
                inetAddressStr = request.getHeader(header)
        }

        if (!inetAddressStr)
            inetAddressStr = request.remoteAddr

        inetAddressStr = findExternalInetAddress(inetAddressStr)

        InetAddress.getByName(inetAddressStr);
    }

    /**
     * For a comma separated list of addresses discards private ones.
     * @param inetAddressStr A possibly comma separated list of addresses
     * @return the non private address if the original inetAddressStr was a list, inetAddressStr otherwise
     */
    private String findExternalInetAddress(String inetAddressStr) {


        if(inetAddressStr && inetAddressStr.contains(',')) {
            // Address is of the form ip1, ip2, ...
            // Let's take the first address only
            String[] ipAddressesStr = inetAddressStr.trim().split(/,\s*/)

            String result = ipAddressesStr.find {
                InetAddress inetAddress = InetAddress.getByName(it.trim());

                !inetAddress.isAnyLocalAddress() && !inetAddress.isSiteLocalAddress() &&
                !inetAddress.isLinkLocalAddress() && !inetAddress.isLoopbackAddress()
            }
            result
        } else {
            inetAddressStr
        }
    }

    /**
     * gets Obtains the Location for a client request
     * @param request the client request
     * @return the Location for the requesting client IP Address or null if the GeoIP database could not be found.
     */
    Location getLocation(HttpServletRequest request ) {
        if(reader) {
            try {
                InetAddress ipAddress = getIpAddress(request)
                CityResponse response = reader.city(ipAddress);
                return response.location
            } catch (Exception ex) {
                log.warn("Error getting MaxMind location: " + ex.message)
                log.debug("Error getting MaxMind location. ", ex)
            }
        }
        return null
    }
}
