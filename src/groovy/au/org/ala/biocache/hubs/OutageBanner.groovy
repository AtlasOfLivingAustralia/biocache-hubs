/* *************************************************************************
 *  Copyright (C) 2014 Atlas of Living Australia
 *  All Rights Reserved.
 * 
 *  The contents of this file are subject to the Mozilla Public
 *  License Version 1.1 (the "License"); you may not use this file
 *  except in compliance with the License. You may obtain a copy of
 *  the License at http://www.mozilla.org/MPL/
 * 
 *  Software distributed under the License is distributed on an "AS
 *  IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 *  implied. See the License for the specific language governing
 *  rights and limitations under the License.
 ***************************************************************************/
package au.org.ala.biocache.hubs

import grails.validation.Validateable
import org.apache.commons.lang.time.DateUtils

import java.text.SimpleDateFormat

/**
 * Command object for outage banner (admin function)
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@Validateable
class OutageBanner {
    String message
    String startDate
    String endDate
//    @DateTimeFormat(iso=DateTimeFormat.ISO.DATE)
//    @BindingFormat('yyyy-MM-dd')
//    Date startDate;
//    @DateTimeFormat(iso=DateTimeFormat.ISO.DATE)
//    @BindingFormat('yyyy-MM-dd')
//    Date endDate;
    Boolean showMessage

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("OutageBanner{");
        sb.append("message='").append(message).append('\'');
        sb.append(", startDate=").append(startDate);
        sb.append(", endDate=").append(endDate);
        sb.append(", showMessage=").append(showMessage);
        sb.append('}');
        return sb.toString();
    }

    public Map toMap() {
         Map map = [
                message: message,
                startDate: startDate,
                endDate: endDate,
                showMessage: showMessage
        ]

        return map
    }

    /**
     * Determine whether or not to display the banner
     *
     * @return
     */
    public Boolean showBanner() {
        Boolean displayBanner = false

        if (showMessage && message && !startDate && !endDate) {
            // tickbox is ticked & dates are blank so show banner
            displayBanner = true
        } else if (message && startDate && endDate) {
            // dates are specified so check them
            Date now = new Date()
            Date start = null
            Date end = null
            try {
                start = new SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH).parse(startDate)
                end = new SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH).parse(endDate)
            } catch (java.text.ParseException pe) {
                log.warn "outage banner dates were not parsed (${startDate} || ${endDate}) - ${pe.message}"
            }

            if (DateUtils.isSameDay(now, start) || now.after(start)) {
                if (DateUtils.isSameDay(now, end) || now.before(end)) {
                    // output the banner message
                    displayBanner = true
                } else {
                    log.debug("now is not on or before endDate")
                }
            } else {
                log.debug("now is not on or after startDate")
            }
        } else {
            log.debug "don't show banner"
        }

        displayBanner
    }
}
