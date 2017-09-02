jQuery(document).ready(function() {
    var offset = 150;

    // Function to handle affix width and classes in affix menu on page loading, scrolling or resizing
    function affix() {

        // Fit affix width to its parent's width
        var $affixElement = $('ul[data-spy="affix"]');

        $affixElement.width($affixElement.parent().width());

        // Position of vertical scrollbar
        var position = $(window).scrollTop();
        if (position >= offset) {
            $('.wrapper .section').each(function(i) {
                // Current content block's position less body padding
                var current = $(this).offset().top - offset - 1;

                // Add active class to corresponding affix menu while removing the same from siblings as per position) of current block
                if (current <= position) {
                    $('a', $affixElement).eq(i).addClass('active').siblings().removeClass('active');
                }
            });
        } else {
            $('a', $affixElement).find('.active').removeClass('active').end().find(":first").addClass('active');
        }
    }

    // Call to function on DOM ready
    affix();

    // Call on scroll or resize
    $(window).on('scroll resize', function() {
        affix();
    });

    // Smooth scrolling at click on nav menu item
    $('a[href*=\\#]:not([href=\\#])').click(function() {
        var target = $(this.hash);
        $('html,body').animate({
            scrollTop: target.offset().top - offset
        }, 500);
        return false;
    });
});

$(document).ready(function () {
    $('[data-clampedwidth]').each(function () {
        var elem = $(this);
        var parentPanel = elem.data('clampedwidth');
        var resizeFn = function () {
            var sideBarNavWidth = $(parentPanel).width() - parseInt(elem.css('paddingLeft')) - parseInt(elem.css('paddingRight')) - parseInt(elem.css('marginLeft')) - parseInt(elem.css('marginRight')) - parseInt(elem.css('borderLeftWidth')) - parseInt(elem.css('borderRightWidth'));
            elem.css('width', sideBarNavWidth);
        };

        resizeFn();
        $(window).resize(resizeFn);
    });

});