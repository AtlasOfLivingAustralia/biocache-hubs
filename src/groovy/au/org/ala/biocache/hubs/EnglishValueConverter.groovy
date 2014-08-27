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

import groovy.util.logging.Log4j
import org.grails.databinding.converters.ValueConverter
import java.text.NumberFormat

/**
 * Custom ValueConverter to force double values to be read as EN locale values
 * This fixes issues with non-EN locales removing dot/period (as a comma would be)
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@Log4j
class EnglishValueConverter implements ValueConverter {
    NumberFormat fmt

    EnglishValueConverter() {
        // The number format sent by Dojo components
        // English locale for the decimal separator
        fmt = NumberFormat.getInstance(Locale.ENGLISH);
        // no grouping
        fmt.setGroupingUsed(false);
    }

    boolean canConvert(value) {
        value instanceof String
    }

    def convert(value) {
        Number n = fmt.parse(value)
        return n.floatValue()
    }

    Class<?> getTargetType() {
        return Float.class
    }
}
