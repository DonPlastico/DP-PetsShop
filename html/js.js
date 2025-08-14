$(document).ready(function () {
  // Asegurarse de que todo está oculto al cargar
  $(".main-menu, .pets-list, .purchase-view, .controls").hide();

  window.addEventListener("message", function (event) {
    switch (event.data.action) {
      case "openmenu":
        // Ocultar todos los menús primero
        $(".main-menu, .pets-list, .purchase-view, .controls").hide();
        // Mostrar solo el menú principal
        $(".main-menu").css("display", "flex");
        break;

      case "changename":
        $(".name").html(event.data.name);
        $(".price").html("$" + event.data.price);
        $(".name-2").html(event.data.name);
        $(".price-2").html("$" + event.data.price);
        break;

      case "updatepetname":
        $("#pet-name").text(event.data.name);
        $("#pet-price").text(Number(event.data.price).toLocaleString('es-ES'));
        break;

      case "update":
        $(".name").html(event.data.name);
        $("#balance-list").text(event.data.price);
        break;

      case "add-pet":
        const html = `
          <div class="item">
            <div class="item-text">${event.data.name}</div>
            <div class="item-img" style="background-image: url('./img/${event.data.img}');"></div>
            <div class="prew-but" onclick="pew(${event.data.id}, '${event.data.price}')">
              <i class="fas fa-eye"></i> MOSTRAR MASCOTA
            </div>
          </div>
        `;
        $('#kutucuk').prepend(html);
        break;
    }
  });

  // Botón de cerrar menú principal
  $(".close-btn").click(function () {
    $(".main-menu").css("display", "none");
    $('#kutucuk').empty();
    $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
  });

  // Botón de cancelar compra
  $(".cancel-btn").click(function () {
    $(".purchase-view, .controls").css("display", "none");
    $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
    $.post('http://DP-PetsShop/cam', JSON.stringify({}));
  });

  // Detector de eventos de teclado
  $(document).keydown(function (e) {
    // Tecla ESCAPE
    if (e.which == 27) {
      if ($(".main-menu").is(":visible")) {
        $(".main-menu").css("display", "none");
        $('#kutucuk').empty();
        $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
      }
      if ($(".pets-list").is(":visible")) {
        back();
      }
      if ($(".purchase-view, .controls").is(":visible")) {
        $(".purchase-view, .controls").css("display", "none");
        $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
        $.post('http://DP-PetsShop/cam', JSON.stringify({}));
      }
    }

    // Teclas de flecha para rotar y hacer zoom en la vista de compra
    if ($(".purchase-view, .controls").is(":visible")) {
      let direction = 0;
      if (e.which == 37) { // Flecha izquierda (rotar)
        direction = 1;
        $.post('http://DP-PetsShop/rotatepet', JSON.stringify({ direction: direction }));
      } else if (e.which == 39) { // Flecha derecha (rotar)
        direction = -1;
        $.post('http://DP-PetsShop/rotatepet', JSON.stringify({ direction: direction }));
      } else if (e.which == 38) { // Flecha arriba (zoom in)
        direction = 1;
        $.post('http://DP-PetsShop/zoompet', JSON.stringify({ direction: direction }));
      } else if (e.which == 40) { // Flecha abajo (zoom out)
        direction = -1;
        $.post('http://DP-PetsShop/zoompet', JSON.stringify({ direction: direction }));
      }
    }
  });
});

// Función para mostrar mascota
function pew(id, price) {
  $(".pets-list").css("display", "none");
  $(".purchase-view, .controls").css("display", "flex");
  $('#kutucuk').empty();
  $.post('http://DP-PetsShop/showpet', JSON.stringify({ id: id }));
  $.post('http://DP-PetsShop/prew', JSON.stringify({ id: id }));

  // Obtener el nombre directamente del elemento .item-text
  let name = $(`div[onclick="pew(${id}, '${price}')"]`).siblings(".item-text").text();

  // Actualizar el nombre en la vista de compra
  $("#pet-name").text(name); // Cambiado de .pet-name a #pet-name

  // Actualizar el precio
  $("#pet-price").text(Number(price).toLocaleString('es-ES'));
}

// Función para comprar
$(".buy-button, .buy-btn").click(function () {
  $(".purchase-view, .controls").css("display", "none");
  $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
  $.post('http://DP-PetsShop/buy', JSON.stringify({}));
  $.post('http://DP-PetsShop/cam', JSON.stringify({}));
});

// Función para volver atrás
function back() {
  $('#kutucuk').empty();
  $(".pets-list").css("display", "none");
  $(".main-menu").css("display", "flex");
}

function box1() {
  $.post('http://DP-PetsShop/box-menu', JSON.stringify({}));
  $(".main-menu").css("display", "none");
  $('#kutucuk').empty();
  $(".pets-list").css("display", "flex");
  $("#category-title").text("PERROS");
}

function box2() {
  $.post('http://DP-PetsShop/box-menu2', JSON.stringify({}));
  $(".main-menu").css("display", "none");
  $('#kutucuk').empty();
  $(".pets-list").css("display", "flex");
  $("#category-title").text("GATOS");
}
