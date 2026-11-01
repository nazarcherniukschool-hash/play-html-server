
const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.static("public"));

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    message: "PLAY HTML server is running 🎮"
  });
});

app.get("/api", (req, res) => {
  res.json({
    name: "PLAY HTML",
    version: "1.0.0",
    message: "Welcome to PLAY HTML!"
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`PLAY HTML server running on port ${PORT}`);
});
