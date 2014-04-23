var bookmark;
var toc;
var curr;
var next;

$(function(){

    if ($('#toc').length > 0) {
        $('#toc').css({'background-color': '#eeeeee'});

        //toc = '<div id="toctitle"><h2>Contents</h2></div>';
        toc = '<ul>'

        var headings = $('h2, h3, h4');


        headings.each(function(index) {
            curr = $(this).get(0).nodeName;
            if (index < headings.length - 1) {
                next = headings.get(index + 1).nodeName;
            }
            else {
                next = false;
            }
            bookmark = $(this).html();
            bookmark = $.trim(bookmark).replace(/ /g, '_').toLowerCase();
            $(this).attr('id', bookmark);

            if (curr == 'H2') {
                toc += '<li class="toclevel-1"><a href=#' + bookmark + '><span class="toctext">' + $(this).html() + '</span></a>';
                if (next == 'H3') {
                    toc += '<ul>';
                }
                else if (next == 'H2' || !next) {
                    toc += '</li>';
                }
            }
            else if (curr == 'H3') {
                toc += '<li class="toclevel-2"><a href=#' + bookmark + '><span class="toctext">' + $(this).html() + '</span></a>';
                if (next == 'H4') {
                    toc += '<ul>';
                }
                else if (next == 'H2' || !next) {
                    toc += '</li></ul></li>'
                }
            }
            else if (curr == 'H4') {
                toc += '<li class="toclevel-3"><a href=#' + bookmark + '><span class="toctext">' + $(this).html() + '</span></a></li>';
                if (next == 'H3') {
                    toc += '</ul></li>'
                }
                else if (next == 'H2' || !next) {
                    toc += '</ul></li></ul></li>';
                }
            }


        });
        toc += '</ul>'

        $('#toc').append(toc);
    }

});