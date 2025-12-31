import { createApp } from "vue";
import App from "./App.vue";

const appElement = document.getElementById("app");
if (appElement) {
  createApp(App).mount(appElement);
}
