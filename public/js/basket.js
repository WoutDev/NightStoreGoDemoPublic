// Remember.... just a demo... hehe

$('input').on('keyup', function (e) {
    if (e.keyCode == 13) {
        id = $(this).data('product');

        updateSubtotal(id);
    }
});

$('.refresh-item').click(function () {
    id = $(this).data('product');

    updateSubtotal(id);
});

$('.delete-item').click(function () {
    id = $(this).data('product');

    remove(id);
});

$('#orderbutton').click(function () {
    if (!$(this).is(':disabled')) {
        window.open('/bestel', "_self");
    }
});

function updateSubtotal(id) {
    priceSelector = $('td[data-th="Prijs"][data-product="' + id + '"]');
    amountSelector = $('input[data-product="' + id + '"]');
    value = amountSelector.val();

    if (isNaN(value) || value < 0 || value > 99) {
        value = 1;
        amountSelector.val(1);
    }
    else if (value == 0) {
        remove(id);
        return;
    }

    postProduct(id, value);

    subtotal = parseFloat(priceSelector.text().substring(1)) * parseFloat(value);

    $('td[data-th="Subtotaal"][data-product="' + id + '"]').text('€' + subtotal.toFixed(2));

    updateTotal();
}

function remove(id) {
    postProduct(id, 0);

    parent = $('tr[data-th="Product-Parent"][data-product="' + id + '"]');
    $(parent).empty();
    $(parent).remove();

    updateTotal();

    getBasketData(function (d, s) {
        if (JSON.stringify(d) == '{}') {
            window.location.href = window.location.href;
        }
    });
}

function updateTotal() {
    amount = 0.00;

    $('td[data-th="Subtotaal"]').each(function () {
        amount += parseFloat($(this).text().substring(1));
    });

    $('td[data-th="Total-Small"]').children('strong').text('Totaal €' + amount.toFixed(2));

    $('td[data-th="Total"]').children('strong').text('Totaal €' + amount.toFixed(2));

    if (amount >= parseFloat($('#minprice').text())) {
        $('#pricewarning').hide();
        $('#orderbutton').prop('disabled', false);
    }
    else {
        $('#pricewarning').show();
        $('#orderbutton').prop('disabled', true);
    }
}

function getBasketData(func) {
    shop = $('#shopname');

    $.get('/winkel/' + shop.attr('data-postcode') + '/' + shop.attr('data-slug') + '/getbasket', function (d, s) {
        func(JSON.parse(d), s);
    });
}

function postProduct(product, amount) {
    shop = $('#shopname');

    $.post('/winkel/' + shop.attr('data-postcode') + '/' + shop.attr('data-slug') + '/setitem/' + product + '/' + amount, function (data, status) {
        console.log(status)
    });

    updateBasketCount();
}

function updateBasketCount() {
    getBasketData(function (data, s) {
        length = 0;

        if (JSON.stringify(data) != '{}') {
            for (var i = 0; i < data.length; i++) {
                length += data[i][5];
            }
        }

        $('#basket-size').text(length);
    });
}

$(document).ready(function () {
   updateTotal();
});
