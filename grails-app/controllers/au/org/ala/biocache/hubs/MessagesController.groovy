/* *************************************************************************
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

class MessagesController {
    def messageSource // ExtendedPluginAwareResourceBundleMessageSource
    static defaultAction = "i18n"

    /**
     * Export raw i18n message properties as TEXT for use by JavaScript i18n library
     *
     * @param id - messageSource file name
     * @return
     */
    def i18n(String id) {
        Locale locale = request.locale

        if (id && id.startsWith("messages_")) {
            // Assume standard messageSource file name pattern:
            // messages.properties, messages_en.properties, messages_en_US.properties
            // String locale_suffix = id.replaceFirst(/messages_(.*)/,'$1')
            List locBits = id?.tokenize('_')
            locale = new Locale(locBits[1], locBits[2]?:'')
        }

        Map props = messageSource.listMessageCodes(locale?:request.locale)
        //log.debug "props = ${props}"

        //Alan modified it for outstream utf-8 on 16/08/2014 --- START
        //response.setHeader("Content-type", "text/plain")
        response.setHeader("Content-type", "text/plain; charset=UTF-8")
        //Alan modified it --- END

        def messages = props.collect{ "${it.key}=${it.value}" }

        render ( text: messages.sort().join("\n") )
    }
}
