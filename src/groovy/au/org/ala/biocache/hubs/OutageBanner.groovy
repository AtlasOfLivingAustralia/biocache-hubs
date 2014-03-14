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

import grails.converters.JSON
import grails.validation.Validateable
import org.grails.databinding.BindingFormat
import org.springframework.format.annotation.DateTimeFormat

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
}
