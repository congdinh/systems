import http from "k6/http";

export default function () {
  const url = "https://localhost:9000/whoami";

  const params = {
    headers: {
      Authorization: "TOKEN",
      Clientid: "13711597-B951-4711-8A61-3B5E471C9E14",
    },
  };

  http.get(url, params);
}
