
/*
 * Copyright (C) 2019 Atlas of Living Australia
 * All Rights Reserved.
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

/**
 * Custom Leaflet.draw labels for i18n support
 */
L.drawLocal = {
    draw: {
        toolbar: {
            actions: {
                title: jQuery.i18n.prop('advancedsearch.js.map.canceldrawing'),
                text: jQuery.i18n.prop('advancedsearch.js.map.cancel')
            },
            finish: {
                title: 'Finish drawing',
                text: 'Finish'
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
                marker: 'Draw a marker',
                circlemarker: 'Draw a circlemarker'
            }
        },
        handlers: {
            circle: {
                tooltip: {
                    start: jQuery.i18n.prop('advancedsearch.js.map.circle.tooltip')
                },
                radius: 'Radius'
            },
            circlemarker: {
                tooltip: {
                    start: 'Click map to place circle marker.'
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
                },
                clearAll: {
                    title: jQuery.i18n.prop('advancedsearch.js.map.clearall.title'), //'Clear all layers',
                    text: jQuery.i18n.prop('advancedsearch.js.map.clearall.text') //'Clear All'
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