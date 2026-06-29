#!/bin/bash
# Uso: rode na pasta do repositório do BLOG (blogbolhas)
# bash patch-blog-index.sh

set -e
FILE="index.html"

if [ ! -f "$FILE" ]; then
  echo "ERRO: $FILE não encontrado."
  exit 1
fi

if ! grep -q "signInWithCustomToken" "$FILE"; then
  echo "ℹ signInWithCustomToken não encontrado — já foi removido ou versão diferente."
  exit 0
fi

python3 << 'PYEOF'
with open("index.html") as f:
    html = f.read()

OLD_IMPORT = '  import { getAuth, signInWithPopup, GoogleAuthProvider, signOut,\n    onAuthStateChanged, signInWithCustomToken }\n    from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";'
NEW_IMPORT = '  import { getAuth, signInWithPopup, GoogleAuthProvider, signOut,\n    onAuthStateChanged }\n    from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";'

OLD_TOKEN = """    // Auto-login via token passado pelo site principal (?token=...)
    const urlToken = new URLSearchParams(window.location.search).get("token");
    if (urlToken) {
      signInWithCustomToken(auth, urlToken)
        .then(() => {
          // limpa o token da URL sem recarregar
          const url = new URL(window.location.href);
          url.searchParams.delete("token");
          window.history.replaceState({}, "", url.toString());
        })
        .catch(() => {}); // token inválido/expirado — ignora, segue sem login
    }"""

NEW_TOKEN = """    // Limpa ?token= da URL se vier do site principal
    // (login Firebase é por domínio — usuária loga uma vez aqui com Google e fica logada)
    if (new URLSearchParams(window.location.search).has("token")) {
      const url = new URL(window.location.href);
      url.searchParams.delete("token");
      window.history.replaceState({}, "", url.toString());
    }"""

ok = 0

if OLD_IMPORT in html:
    html = html.replace(OLD_IMPORT, NEW_IMPORT, 1)
    print("  ✓ import — signInWithCustomToken removido")
    ok += 1
else:
    print("  ✗ import não encontrado exatamente — tenta remover manualmente:", ", signInWithCustomToken")
    html = html.replace(", signInWithCustomToken", "", 1)
    ok += 1

if OLD_TOKEN in html:
    html = html.replace(OLD_TOKEN, NEW_TOKEN, 1)
    print("  ✓ bloco urlToken substituído")
    ok += 1
else:
    print("  ✗ bloco urlToken não encontrado — versão diferente?")

if ok > 0:
    with open("index.html", "w") as f:
        f.write(html)
    print(f"\n✦ {ok} correção(ões) aplicada(s). Faz commit e push.")
PYEOF
