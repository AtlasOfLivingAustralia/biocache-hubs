
//= require jquery_migration
//= require jquery.i18n.properties

function leafletI18n() {
    L.drawLocal = {
        draw: {
            toolbar: {
                actions: {
                    title: jQuery.i18n.prop('advancedsearch.js.map.canceldrawing'),
                    text: jQuery.i18n.prop('advancedsearch.js.map.cancel')
                },
                undo: {
                    title: jQuery.i18n.prop('advancedsearch.js.map.deletepointdrawn'),
                    text: jQuery.i18n.prop('advancedsearch.js.map.deletepoint')
                },
                buttons: {
                    polyline: 'Draw a polyline',
                    polygon: jQuery.i18n.prop('advancedsearch.js.map.polygon'),
                    rectangle: jQuery.i18n.prop('advancedsearch.js.map.rectangle'),
                    circle: jQuery.i18n.prop('advancedsearch.js.map.circle'),
                    marker: 'Draw a marker'
                }
            },
            handlers: {
                circle: {
                    tooltip: {
                        start: jQuery.i18n.prop('advancedsearch.js.map.circle.tooltip')
                    }
                },
                marker: {
                    tooltip: {
                        start: 'Click map to place marker.'
                    }
                },
                polygon: {
                    tooltip: {
                        start: jQuery.i18n.prop('advancedsearch.js.map.clicktostart'),
                        cont: jQuery.i18n.prop('advancedsearch.js.map.clicktocontinue'),
                        end: jQuery.i18n.prop('advancedsearch.js.map.clickfirst')
                    }
                },
                polyline: {
                    error: '<strong>'+jQuery.i18n.prop('advancedsearch.js.map.error1')+'</strong> '+jQuery.i18n.prop('advancedsearch.js.map.error2'),
                    tooltip: {
                        start: jQuery.i18n.prop('advancedsearch.js.map.polyline.tooltip.start'),
                        cont: jQuery.i18n.prop('advancedsearch.js.map.polyline.tooltip.cont'),
                        end: jQuery.i18n.prop('advancedsearch.js.map.polyline.tooltip.end')
                    }
                },
                rectangle: {
                    tooltip: {
                        start: jQuery.i18n.prop('advancedsearch.js.map.rectangleguide')
                    }
                },
                simpleshape: {
                    tooltip: {
                        end: jQuery.i18n.prop('advancedsearch.js.map.finish')
                    }
                }
            }
        },
        edit: {
            toolbar: {
                actions: {
                    save: {
                        title: jQuery.i18n.prop('advancedsearch.js.map.save.title'),
                        text: jQuery.i18n.prop('advancedsearch.js.map.save.text')
                    },
                    cancel: {
                        title: jQuery.i18n.prop('advancedsearch.js.map.cancel.title'),
                        text: jQuery.i18n.prop('advancedsearch.js.map.cancel.text')
                    }
                },
                buttons: {
                    edit: jQuery.i18n.prop('advancedsearch.js.map.edit'),
                    editDisabled: jQuery.i18n.prop('advancedsearch.js.map.noedit'),
                    remove: jQuery.i18n.prop('advancedsearch.js.map.remove'),
                    removeDisabled: jQuery.i18n.prop('advancedsearch.js.map.nodelete')
                }
            },
            handlers: {
                edit: {
                    tooltip: {
                        text: jQuery.i18n.prop('advancedsearch.js.map.edit.tooltip.text'),
                        subtext: jQuery.i18n.prop('advancedsearch.js.map.edit.tooltip.subtext')
                    }
                },
                remove: {
                    tooltip: {
                        text: jQuery.i18n.prop('advancedsearch.js.map.remove.tooltip')
                    }
                }
            }
        }
    };
}
