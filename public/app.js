
const searchInput = document.getElementById("search");
const gamesContainer = document.getElementById("games");

const games = [
  {
    name: "Ігри скоро з'являться!",
    description: "Незабаром тут будуть цікаві HTML-ігри.",
    icon: "🎮",
    category: "Усі ігри"
  }
];

function renderGames(list) {
  gamesContainer.innerHTML = "";

  if (list.length === 0) {
    gamesContainer.innerHTML =
      "<p>😕 Ігор за твоїм запитом не знайдено.</p>";
    return;
  }

  list.forEach(game => {
    const card = document.createElement("article");
    card.className = "game";

    const icon = document.createElement("div");
    icon.className = "game-icon";
    icon.textContent = game.icon;

    const title = document.createElement("h3");
    title.textContent = game.name;

    const description = document.createElement("p");
    description.textContent = game.description;

    card.append(icon, title, description);
    gamesContainer.appendChild(card);
  });
}

searchInput.addEventListener("input", () => {
  const query = searchInput.value.trim().toLowerCase();

  const filtered = games.filter(game =>
    (game.name + " " + game.description + " " + game.category)
      .toLowerCase()
      .includes(query)
  );

  renderGames(filtered);
});

renderGames(games);
