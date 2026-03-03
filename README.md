# PARKIFY - Seminarski Rad
## Razvoj Softvera II

---

## Upute za Pokretanje

### 1. Backend Setup

```bash
docker-compose up --build
```

Docker će automatski buildati aplikaciju, seedati bazu sa test podacima i pokrenuti API.

### 2. Export Aplikacija

```bash
Export: fit-build-2026-03-03.zip
```

Zip sadrži dva foldera:

- `Release/` — Desktop aplikacija (.exe)
- `flutter-apk/` — Mobilna aplikacija (parkify.apk)

---

## Pokretanje Mobilne Aplikacije

**Preduvjeti:** Android Emulator pokrenut, APK fajl iz `flutter-apk/parkify.apk`

1. Otvoriti Android Emulator
2. Prevući `parkify.apk` u emulator (drag & drop)
4. Otvoriti aplikaciju

---

## Pokretanje Desktop Aplikacije

1. Otvoriti `Release/` folder
2. Dvostruki klik na `Parkify.exe`

---

## Kredencijali

### Admin Korisnik
```
Korisničko ime: admin
Lozinka:        Test123!
```
Pristup: Desktop aplikacija — administratorske funkcije, pregled svih parking zona i rezervacija...

### Test Korisnik
```
Korisničko ime: user
Lozinka:        Test123!
```
Pristup: Normalne korisničke funkcije — pronalaženje parking mjesta, rezervacije, recenzije...

---

## Stripe — Testiranje Plaćanja

Stripe je integriran za sigurna plaćanja. Za testiranje koristi:

```
Broj kartice:  4242 4242 4242 4242
CVC:           Bilo koje 3 cifre
Datum isteka:  Bilo koji datum u budućnosti
```

**Gdje testirati plaćanja:**

Na parking zoni na mapi ili u novčaniku.

---

## Notifikacijski Sistem

Sistem šalje notifikacije putem tri kanala: In-App (push), Email i oba kanala istovremeno. Kanal se bira pri slanju iz admin panela ili je određen tipom događaja.

### Kada se šalju notifikacije

| Tip | Okidač | Kanal |
|-----|--------|-------|
| Potvrda rezervacije | Korisnik kreira rezervaciju | In-App + Email |
| Plaćanje uspješno | Stripe potvrdi transakciju | In-App + Email |
| Plaćanje neuspješno | Stripe odbije transakciju | In-App + Email |
| Podsjetnik za rezervaciju | 30 minuta prije početka rezervacije (job) | In-App |
| Check-in podsjetnik | Rezervacija postane aktivna | In-App |
| Otkazana rezervacija | Admin ili korisnik otkaže rezervaciju | In-App + Email |
| No-show | Job detektuje neiskorištenu rezervaciju | In-App |
| Obavijest o dostupnosti | Admin ručno šalje iz panela | In-App |
| Posebna ponuda | Admin ručno šalje iz panela | Email (ako korisnik ima uključen `NotifyAboutOffers`) |
| Parking pun | Popunjenost zone dosegne 100% | In-App |

> Email za tip "Posebna ponuda" neće biti poslan korisnicima koji imaju isključen `NotifyAboutOffers` u preferencama.

---

## Automatski Job — ReservationStatusJob

`ReservationStatusJob` je pozadinski servis koji se pokreće automatski svakih **10 minuta** i vrši sljedeće radnje:

**Aktivacija rezervacija** — Sve rezervacije sa statusom `Confirmed` čiji je `ReservationStart` prošao, a `ReservationEnd` još nije, prebacuje u status `Active`.

**Završavanje rezervacija** — Sve rezervacije sa statusom `Active` čiji je `ReservationEnd` prošao, prebacuje u status `Completed` i oslobađa parking mjesto (`IsAvailable = true`).

**Detekcija No-Show** — Sve rezervacije sa statusom `Confirmed` kod kojih je `ReservationStart` prošao više od 30 minuta, a korisnik se nije check-inao, prebacuje u status `NoShow`, oslobađa parking mjesto i šalje In-App notifikaciju korisniku.

**Podsjetnici** — Za svaku `Confirmed` rezervaciju čiji `ReservationStart` je u sljedećih 30 minuta, a podsjetnik još nije poslan, šalje In-App notifikaciju korisniku i bilježi da je podsjetnik poslan.

---
