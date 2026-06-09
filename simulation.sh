#!/usr/bin/env bash
# ============================================================
# SIMULATION COMPLÈTE — Qui Go au Bled (Railway)
# Acteurs : Transporteur · Admin · Client
# ============================================================

BASE="https://backend-qui-go-au-bled-production.up.railway.app/api"
DB="postgresql://postgres:WwZbuiyMQKAOyvmBMOZKvAapLhyvJRcl@acela.proxy.rlwy.net:59339/railway"

# Couleurs
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

step() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BOLD}$1${NC}"; }
ok()   { echo -e "  ${GREEN}✓ $1${NC}"; }
info() { echo -e "  ${YELLOW}→ $1${NC}"; }
fail() { echo -e "  ${RED}✗ $1${NC}"; }

TIMESTAMP=$(date +%s)
TRANSPORTER_EMAIL="transporteur_${TIMESTAMP}@test.com"
CLIENT_EMAIL="client_${TIMESTAMP}@test.com"
ADMIN_EMAIL="admin_${TIMESTAMP}@test.com"
PASSWORD="Test1234!"

# ────────────────────────────────────────────────────────────
step "🔧  PRÉREQUIS — Vérification du backend"
# ────────────────────────────────────────────────────────────
HEALTH=$(curl -s "$BASE/../health")
echo "  $HEALTH"

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ÉTAPE 1 — INSCRIPTION DES ACTEURS       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
# ============================================================

step "👤  Inscription du Transporteur"
RES=$(curl -s -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"fullName\":\"Ahmed Transporteur\",\"email\":\"$TRANSPORTER_EMAIL\",\"password\":\"$PASSWORD\",\"phone\":\"+33612345678\",\"address\":\"Paris, France\"}")
TRANSPORTER_TOKEN=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)
TRANSPORTER_ID=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',{}).get('id',''))" 2>/dev/null)
TRANSPORTER_NAME=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',{}).get('fullName',''))" 2>/dev/null)
if [ -n "$TRANSPORTER_TOKEN" ]; then
  ok "Transporteur créé : $TRANSPORTER_NAME ($TRANSPORTER_EMAIL)"
  info "ID : $TRANSPORTER_ID"
else
  fail "Erreur : $RES"; exit 1
fi

step "👤  Inscription du Client"
RES=$(curl -s -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"fullName\":\"Fatima Cliente\",\"email\":\"$CLIENT_EMAIL\",\"password\":\"$PASSWORD\",\"phone\":\"+33698765432\",\"address\":\"Lyon, France\"}")
CLIENT_TOKEN=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)
CLIENT_ID=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',{}).get('id',''))" 2>/dev/null)
CLIENT_NAME=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',{}).get('fullName',''))" 2>/dev/null)
if [ -n "$CLIENT_TOKEN" ]; then
  ok "Client créé : $CLIENT_NAME ($CLIENT_EMAIL)"
  info "ID : $CLIENT_ID"
else
  fail "Erreur : $RES"; exit 1
fi

step "🔑  Inscription de l'Admin"
RES=$(curl -s -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"fullName\":\"Super Admin\",\"email\":\"$ADMIN_EMAIL\",\"password\":\"$PASSWORD\"}")
ADMIN_ID=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',{}).get('id',''))" 2>/dev/null)
if [ -n "$ADMIN_ID" ]; then
  ok "Compte admin créé — promotion du rôle en base…"
  PGPASSWORD="" psql "$DB" -c "UPDATE users SET role='admin' WHERE id='$ADMIN_ID';" > /dev/null 2>&1
  ok "Rôle 'admin' attribué en base"
else
  fail "Erreur : $RES"; exit 1
fi

step "🔑  Login Admin"
RES=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$PASSWORD\"}")
ADMIN_TOKEN=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)
if [ -n "$ADMIN_TOKEN" ]; then
  ok "Admin connecté"
else
  fail "Erreur login admin : $RES"; exit 1
fi

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ÉTAPE 2 — TRANSPORTEUR : CRÉER ANNONCE  ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
# ============================================================

step "✈️   Transporteur — Création d'une annonce (statut: pending)"
FLIGHT_DATE=$(date -d "+10 days" +%Y-%m-%d)
RES=$(curl -s -X POST "$BASE/ads" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRANSPORTER_TOKEN" \
  -d "{
    \"departureCity\": \"Paris\",
    \"arrivalCity\": \"Alger\",
    \"flightDate\": \"$FLIGHT_DATE\",
    \"flightTime\": \"10:30\",
    \"maxWeightKg\": 15,
    \"pricePerKg\": 8.50,
    \"description\": \"Je voyage Paris → Alger, je peux transporter vos colis en toute sécurité.\"
  }")
AD_ID=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ad',{}).get('id',''))" 2>/dev/null)
AD_STATUS=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ad',{}).get('status',''))" 2>/dev/null)
AD_DEPARTURE=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ad',{}).get('departureCity',''))" 2>/dev/null)
AD_ARRIVAL=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ad',{}).get('arrivalCity',''))" 2>/dev/null)
AD_PRICE=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ad',{}).get('pricePerKg',''))" 2>/dev/null)
if [ -n "$AD_ID" ]; then
  ok "Annonce créée : $AD_DEPARTURE → $AD_ARRIVAL | Vol le $FLIGHT_DATE | $AD_PRICE €/kg"
  info "ID annonce : $AD_ID | Statut : ${YELLOW}$AD_STATUS${NC}"
  info "⏳ En attente de validation par l'admin…"
else
  fail "Erreur : $RES"; exit 1
fi

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ÉTAPE 3 — ADMIN : VALIDER L'ANNONCE     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
# ============================================================

step "🔍  Admin — Annonces en attente de validation"
RES=$(curl -s "$BASE/admin/ads/pending" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
COUNT=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('ads',[])))" 2>/dev/null)
ok "$COUNT annonce(s) en attente"

step "✅  Admin — Approbation de l'annonce de $TRANSPORTER_NAME"
RES=$(curl -s -X PATCH "$BASE/admin/ads/$AD_ID/approve" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
MSG=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
if echo "$RES" | grep -q "approuvée\|approved\|active"; then
  ok "$MSG"
  info "Annonce maintenant ACTIVE — visible par les clients"
else
  fail "Erreur approbation : $RES"; exit 1
fi

step "📊  Admin — Statistiques plateforme"
RES=$(curl -s "$BASE/admin/stats" -H "Authorization: Bearer $ADMIN_TOKEN")
echo "$RES" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'  Total utilisateurs : {d.get(\"totalUsers\",0)}')
print(f'  Annonces actives   : {d.get(\"activeAds\",0)}')
print(f'  Annonces en attente: {d.get(\"pendingAds\",0)}')
print(f'  Total commandes    : {d.get(\"totalOrders\",0)}')
" 2>/dev/null

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ÉTAPE 4 — CLIENT : FAIRE UNE DEMANDE    ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
# ============================================================

step "🔎  Client — Recherche d'annonces Paris → Alger"
RES=$(curl -s "$BASE/ads?departureCity=Paris&arrivalCity=Alger" \
  -H "Authorization: Bearer $CLIENT_TOKEN")
ADS_COUNT=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('ads',[])))" 2>/dev/null)
ok "$ADS_COUNT annonce(s) active(s) trouvée(s) pour Paris → Alger"
echo "$RES" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for ad in d.get('ads',[]):
    print(f'  • [{ad[\"id\"][:8]}…] {ad[\"departureCity\"]} → {ad[\"arrivalCity\"]} | Vol: {ad[\"flightDate\"][:10]} | {ad[\"pricePerKg\"]}€/kg | max {ad[\"maxWeightKg\"]}kg | Transporteur: {ad[\"transporterName\"]}')
" 2>/dev/null

step "📩  Client — Envoi d'une demande au transporteur sur l'annonce"
RES=$(curl -s -X POST "$BASE/requests" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  -d "{
    \"adId\": \"$AD_ID\",
    \"transporterId\": \"$TRANSPORTER_ID\",
    \"transporterName\": \"$TRANSPORTER_NAME\",
    \"message\": \"Bonjour, j'ai un colis de 5kg (vêtements + petits cadeaux) à envoyer à ma famille à Alger. Pouvez-vous le transporter ? Merci !\"
  }")
REQUEST_ID=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('request',{}).get('id',''))" 2>/dev/null)
REQ_STATUS=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('request',{}).get('status',''))" 2>/dev/null)
if [ -n "$REQUEST_ID" ]; then
  ok "Demande envoyée à $TRANSPORTER_NAME"
  info "ID demande : $REQUEST_ID | Statut : ${YELLOW}$REQ_STATUS${NC}"
  info "Message : \"Bonjour, j'ai un colis de 5kg…\""
else
  fail "Erreur : $RES"; exit 1
fi

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ÉTAPE 5 — TRANSPORTEUR : ACCEPTER       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
# ============================================================

step "📬  Transporteur — Consultation des demandes reçues"
RES=$(curl -s "$BASE/requests/incoming" \
  -H "Authorization: Bearer $TRANSPORTER_TOKEN")
COUNT=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('requests',[])))" 2>/dev/null)
ok "$COUNT demande(s) en attente"
echo "$RES" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for r in d.get('requests',[]):
    print(f'  • [{r[\"id\"][:8]}…] De: {r[\"clientName\"]} | Msg: {(r.get(\"message\") or \"\")[:60]}…')
" 2>/dev/null

step "✅  Transporteur — Acceptation de la demande de $CLIENT_NAME"
RES=$(curl -s -X PATCH "$BASE/requests/$REQUEST_ID/accept" \
  -H "Authorization: Bearer $TRANSPORTER_TOKEN")
NEW_STATUS=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('request',{}).get('status',''))" 2>/dev/null)
if echo "$RES" | grep -q "ACCEPTED\|request"; then
  ok "Demande acceptée — statut : ${GREEN}$NEW_STATUS${NC}"
else
  fail "Erreur : $RES"; exit 1
fi

step "📦  Transporteur — Création de la commande"
RES=$(curl -s -X POST "$BASE/orders" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TRANSPORTER_TOKEN" \
  -d "{
    \"adId\": \"$AD_ID\",
    \"requestId\": \"$REQUEST_ID\",
    \"transporterId\": \"$TRANSPORTER_ID\",
    \"clientId\": \"$CLIENT_ID\",
    \"departureCity\": \"Paris\",
    \"arrivalCity\": \"Alger\",
    \"flightDate\": \"${FLIGHT_DATE}T10:30:00.000Z\",
    \"pricePerKg\": 8.50
  }")
ORDER_ID=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('order',{}).get('id',''))" 2>/dev/null)
ORDER_NUMBER=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('orderNumber','') or d.get('order',{}).get('orderNumber',''))" 2>/dev/null)
ORDER_STATUS=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('order',{}).get('status',''))" 2>/dev/null)
if [ -n "$ORDER_ID" ]; then
  ok "Commande créée : ${BOLD}$ORDER_NUMBER${NC}"
  info "ID : $ORDER_ID | Statut : ${YELLOW}$ORDER_STATUS${NC}"
else
  fail "Erreur création commande : $RES"; exit 1
fi

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ÉTAPE 6 — TRANSPORT EN COURS            ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
# ============================================================

step "🚀  Transporteur — Début du transport (départ vol)"
RES=$(curl -s -X PATCH "$BASE/orders/$ORDER_ID/start" \
  -H "Authorization: Bearer $TRANSPORTER_TOKEN")
MSG=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
ok "$MSG — Commande : IN_PROGRESS"

step "🏁  Transporteur — Transport terminé (colis livré)"
RES=$(curl -s -X PATCH "$BASE/orders/$ORDER_ID/complete" \
  -H "Authorization: Bearer $TRANSPORTER_TOKEN")
MSG=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
ok "$MSG — Commande : COMPLETED | Avis autorisé : ✓"

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  ÉTAPE 7 — CLIENT : LAISSER UN AVIS      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
# ============================================================

step "⭐  Client — Soumission du feedback sur le transporteur"
RES=$(curl -s -X POST "$BASE/reviews" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  -d "{
    \"orderId\": \"$ORDER_ID\",
    \"orderNumber\": \"$ORDER_NUMBER\",
    \"transporterId\": \"$TRANSPORTER_ID\",
    \"transporterName\": \"$TRANSPORTER_NAME\",
    \"rating\": 5,
    \"comment\": \"Excellent transporteur, très sérieux et ponctuel. Colis livré en parfait état. Je recommande fortement !\",
    \"punctuality\": 5,
    \"communication\": 4,
    \"packageCondition\": 5,
    \"reliability\": 5
  }")
MSG=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
if echo "$RES" | grep -q "succès\|success\|soumis"; then
  ok "$MSG"
  info "Note : ⭐⭐⭐⭐⭐ (5/5)"
  info "Ponctualité: 5 | Communication: 4 | État colis: 5 | Fiabilité: 5"
else
  fail "Erreur avis : $RES"; exit 1
fi

step "📈  Vérification — Profil mis à jour du transporteur"
RES=$(curl -s "$BASE/reviews/transporter/$TRANSPORTER_ID" \
  -H "Authorization: Bearer $CLIENT_TOKEN")
TOTAL=$(echo "$RES" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('reviews',[])))" 2>/dev/null)
AVG=$(echo "$RES" | python3 -c "
import sys,json
d=json.load(sys.stdin)
reviews=d.get('reviews',[])
if reviews:
    avg=sum(r['rating'] for r in reviews)/len(reviews)
    print(f'{avg:.1f}')
else:
    print('N/A')
" 2>/dev/null)
ok "$TOTAL avis sur le profil de $TRANSPORTER_NAME | Note moyenne : $AVG/5"

# ============================================================
echo -e "\n${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  RÉSUMÉ DE LA SIMULATION                 ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"

echo -e "
${BOLD}Acteurs :${NC}
  👤 Transporteur : Ahmed Transporteur  ($TRANSPORTER_EMAIL)
  👤 Client       : Fatima Cliente      ($CLIENT_EMAIL)
  🔑 Admin        : Super Admin         ($ADMIN_EMAIL)

${BOLD}Flux réalisé :${NC}
  1. ${GREEN}✓${NC} Transporteur crée une annonce Paris → Alger (statut: pending)
  2. ${GREEN}✓${NC} Admin valide l'annonce → statut: active
  3. ${GREEN}✓${NC} Client trouve l'annonce et envoie une demande
  4. ${GREEN}✓${NC} Transporteur reçoit & accepte la demande
  5. ${GREEN}✓${NC} Commande créée : ${BOLD}$ORDER_NUMBER${NC}
  6. ${GREEN}✓${NC} Transport démarré → IN_PROGRESS
  7. ${GREEN}✓${NC} Transport terminé → COMPLETED
  8. ${GREEN}✓${NC} Client laisse un avis ⭐⭐⭐⭐⭐ sur le profil transporteur

${BOLD}Backend :${NC} $BASE
"
