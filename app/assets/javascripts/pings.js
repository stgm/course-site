async function keepalive() {
  try {
    await fetch("/profile/ping", {
      method: "GET",
      credentials: "same-origin"
    });
  } catch (error) {
    // Silently ignore errors
  }

  setTimeout(keepalive, 600000); // schedule next ping in 10 minutes
}

document.addEventListener("DOMContentLoaded", () => {
  setTimeout(keepalive, 2000);
});
