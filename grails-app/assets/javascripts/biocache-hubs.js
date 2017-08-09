/**
 * Created by SaMa on 23/9/15.
 */
/************************************************************\
 * i18n
 \************************************************************/
if (typeof BC_CONF != 'undefined' && BC_CONF.hasOwnProperty('contextPath')) {
    jQuery.i18n.properties({
        name: 'messages',
        path: BC_CONF.contextPath + '/messages/i18n/',
        mode: 'map',
        language: BC_CONF.locale // default is to use browser specified locale
    });
}
