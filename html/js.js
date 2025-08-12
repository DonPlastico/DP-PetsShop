$(document).ready(function () {
  // Asegurarse de que todo está oculto al cargar
  $(".main-menu, .pets-list, .purchase-view, .pet-menu").hide();
  window.addEventListener("message", function (event) {
    switch (event.data.action) {
      case "openmenu":
        // Ocultar todos los menús primero
        $(".main-menu, .pets-list, .purchase-view, .pet-menu").hide();
        // Mostrar solo el menú principal
        $(".main-menu").css("display", "flex");
        break;

      case "changename":
        $(".name").html(event.data.name);
        $(".price").html("$" + event.data.price);
        $(".name-2").html(event.data.name);
        $(".price-2").html("$" + event.data.price);
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
                        <div class="prew-but" onclick="pew(this.id)" id="${event.data.id}">
                            <i class="fas fa-eye"></i> MOSTRAR MASCOTA
                        </div>
                    </div>
                `;
        $('#kutucuk').prepend(html);
        break;

      case "open-menu-d":
        $(".pet-menu").css("display", "flex");
        break;
    }
  });

  // Botón de cerrar menú principal
  $(".close-btn").click(function () {
    $(".main-menu").css("display", "none");
    $('#kutucuk').empty();
    $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
  });

  // Botón de cerrar menú de mascota
  $(".close-pet-menu").click(function () {
    $(".pet-menu").css("display", "none");
    $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
  });

  // Botón de cancelar compra
  $(".cancel-btn").click(function () {
    $(".purchase-view").css("display", "none");
    $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
    $.post('http://DP-PetsShop/cam', JSON.stringify({}));
  });
});

// Función para mostrar mascota
function pew(id) {
  $(".pets-list").css("display", "none");
  $(".purchase-view").css("display", "flex");
  $('#kutucuk').empty();
  $.post('http://DP-PetsShop/showpet', JSON.stringify({ id: id }));
}

// Función para comprar
$(".buy-button, .buy-btn").click(function () {
  $(".purchase-view").css("display", "none");
  $.post('http://DP-PetsShop/closenui', JSON.stringify({}));
  $.post('http://DP-PetsShop/cam', JSON.stringify({}));
  $.post('http://DP-PetsShop/buy', JSON.stringify({}));
});

// Función para volver atrás
function back() {
  $('#kutucuk').empty();
  $(".pets-list").css("display", "none");
  $(".main-menu").css("display", "flex");
}

// Funciones de control de mascota
function spawnpet() {
  $.post('http://DP-PetsShop/spawnpet', JSON.stringify({}));
}

function vehicle() {
  $.post('http://DP-PetsShop/vehicle', JSON.stringify({}));
}

function sit() {
  $.post('http://DP-PetsShop/sit', JSON.stringify({}));
}

function sleep() {
  $.post('http://DP-PetsShop/sleep', JSON.stringify({}));
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

function deletela() {
  $(".pet-menu").css("display", "none");
  $.post('http://DP-PetsShop/delete', JSON.stringify({}));
}