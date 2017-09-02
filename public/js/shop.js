// Remember.... just a demo... hehe

$(document).ready(function () {
    updateShopItemList();
});

$('#btn-submit').click(function() {
    amount = $('#amount').val();

    if (isNaN(amount) || amount < 0 || amount > 99)
    {
        amount = 0;
    }

    $.post({
        url: $('#shopname').attr('data-slug') + '/setitem/' + $(this).attr('data-product') + '/' + amount,
        success: function(data) {
            console.log(status)
        }
    });

    setTimeout(updateBasketCount, 250);
    setTimeout(updateShopItemList, 250);
});

function updateBasketCount() {
    getBasketData(function(data)
    {
        length = 0;

        if (JSON.stringify(data) != '{}')
        {
            for (var i = 0; i < data.length; i++)
            {
                length += data[i][5];
            }
        }

        $('#basket-size').html(length);
        $('#basket-size-xs').html(length);
    });
}

function updateShopItemList() {
    getBasketData(function(data)
    {
        if ('error' in data) {
            $('button').each(function() {
                $(this).removeClass("add");
                $(this).prop('disabled', true);
            });

            return;
        }

        $('.col-lg-12 .col-lg-9').children().each(function() {
            if ($(this).is('.panel'))
            {
                if ($(this).is('.panel-info'))
                {
                    var found = false;
                    var d = null;

                    for (var i = 0; i < data.length; i++)
                    {
                        var obj = data[i];

                        if ($(this).attr('id') == (obj[1] + '-header'))
                        {
                            found = true;
                            d = obj;
                        }
                    }

                    id = $(this).attr('id').substring(0, $(this).attr('id').length - 7);

                    priceElement = $('#' + id + '-price');
                    buttonElement = $('a[data-product="' + id + '"]');

                    if (!found)
                    {
                        $(this).removeClass('panel-info');
                        $(this).addClass('panel-default');

                        priceElement.text(priceElement.text().split(' ')[1]);
                        buttonElement.text('Koop');
                    }
                    else
                    {
                        priceElement.text(d[5] + 'x €' + d[2].toFixed(2));
                        buttonElement.text('Pas aan');
                    }
                }
                else if ($(this).is('.panel-default'))
                {
                    for (var i = 0; i < data.length; i++)
                    {
                        var obj = data[i];

                        if ($(this).attr('id') == (obj[1] + '-header'))
                        {
                            $(this).removeClass('panel-default');
                            $(this).addClass('panel-info');

                            id = $(this).attr('id').substring(0, $(this).attr('id').length - 7);

                            priceElement = $('#' + id + '-price');

                            priceElement.text(obj[5] + 'x €' + obj[2].toFixed(2));

                            buttonElement = $('a[data-product="' + id + '"]');
                            buttonElement.text('Pas aan');
                        }
                    }
                }
            }
        });
    });
}

function getBasketData(func)
{
    $.get({
        url: $('#shopname').attr('data-slug') + '/getbasket',
        success: function(data)
        {
            func(JSON.parse(data));
        }
    })
}

$('body').on('click', '.add', function(ev) {
    ev.preventDefault ? ev.preventDefault() : (ev.returnValue = false);

    var product = $(this).attr('data-product');

    $.get($('#shopname').attr('data-slug') + '/getbasket/' + product, function(data, status) {
        var json = JSON.parse(data);

        $('#productModal').find('#amount').val(json['amount'] == 0 ? 1 : json['amount']);

        // title = '<h3>' + json['name'] + '<span class="pull-right">€' + json['price'].toFixed(2) + '</span></h3>';
        title = '<h3>' + json['name'] + '<span class="pull-right" id="total-price">Totaal: €' + (json['price'] * $('#amount').val()).toFixed(2) + '</span></h3>';
        title += '<span id="price">€' + json['price'].toFixed(2) + '</span>';
        body = '<strong>Beschrijving: </strong>';
        body += '<p>' + json['description'] + '</p>';
        body += '<br />';

        if (json['min_age'] != 0)
        {
            body += '<strong>Verplichte leeftijd: </strong>';
            body += json['min_age'];
        }

        $('#productModal').find('.modal-title').html(title);
        $('#productModal').find('.modal-body').html(body);
        $('#productModal').find('#btn-submit').attr('data-product', product);
        $('#productModal').modal('show');
    });
});

$('#btn-plus').click(function(ev) {
    ev.preventDefault ? ev.preventDefault() : (ev.returnValue = false);

    var num = +$("#amount").val() + 1;

    if (num > 99)
        return;

    $("#amount").val(num);

    updateTotal();
});

$('#btn-min').click(function(ev) {
    ev.preventDefault ? ev.preventDefault() : (ev.returnValue = false);

    var num = +$("#amount").val() - 1;

    if (num < 0)
        return;

    $("#amount").val(num);

    updateTotal();
});

$('#amount').on('keyup', function(e) {
   if (e.keyCode == 13)
   {
       amount = $('#amount').val();

       if (isNaN(amount) || amount < 0 || amount > 99)
           return;

       updateTotal();
   }
});

function updateTotal()
{
    $('#total-price').text("Totaal: €" + (parseFloat($('#price').text().substring(1)) * $('#amount').val()).toFixed(2));
}