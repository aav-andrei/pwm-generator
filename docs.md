
# Generator semnal PWM

Acest proiect implementeaza un periferic hardware configurabil pentru generarea semnalelor PWM, controlat printr-o interfata SPI si compus din module hardware scrise in Verilog. Implementarea urmeaza specificatiile din enuntul temei.

## Structura proiectului:
- top.v – modul principal, leaga toate submodulele
- spi_bridge.v – implementeaza interfata SPI si conversia serial–paralel
- instr_dcd.v – decodifica instructiunile primite prin SPI
- regs.v – bloc de registri mapati in adresa
- counter.v – numarator cu prescaler si directie configurabila
- pwm_gen.v – generator semnal PWM pe baza valorilor din registri

Toate modulele folosesc ceasul intern clk. SPI transmite date in pachete de cate 8 biti, MSB primul.

----------

## 1. top.v — Nivel de ansamblu

Rol: interconecteaza SPI, decodorul, blocul de registri, numaratorul si generatorul PWM.

### Semnale principale:
- clk, rst_n — ceas si reset intern
- sclk, cs_n, miso — intrari SPI
- mosi — iesire SPI
- pwm_out — iesire semnal PWM

### Flux date:  
SPI → spi_bridge → instr_dcd → regs → counter → pwm_gen → pwm_out

----------

## 2. spi_bridge.v — Interfata SPI

### Rol:
- primeste biti si ii paralelizeaza
- transmite biti din paralel in serial
- genereaza byte_sync cand un byte complet a fost receptionat

### Mecanism:
- shift pe front crescator SCLK (intrare miso)
- shift out pe front descrescator SCLK (iesire mosi)
- MSB first
- CPOL = 0, CPHA = 0

### Cand bit_cnt ajunge la 7:
- data_in devine valid
- byte_sync se activeaza 1 ciclu
- shift_out se reincarca cu data_out pentru transmiterea urmatorului byte

----------

## 3. instr_dcd.v — Decodor instructiuni

### Protocol pe doua byte-uri:
Byte 1 (setup):  
Bit 7: R/W (1 = write, 0 = read)  
Bit 6: High/Low (1 = MSB, 0 = LSB)  
Bitii 5:0: adresa registrului
Byte 2 (data):  
Contine datele ce se scriu in registru sau este byte-ul de clock pentru citire.

### Stari interne:
- first_byte — indica daca urmatorul byte e setup sau data
- rw_flag — retine tipul operatiunii
- high_flag — selecteaza MSB/LSB
- reg_addr — adresa de baza
- 
### Output catre regs.v:  
read, write, addr, data_write, data_out (pasare spre spi_bridge)

----------

# 4. regs.v — Blocul de registri

### Rol:  
Stocheaza parametrii perifericului si expune API-ul de configurare prin SPI.

Adresarea se face pe 6 biti:
- addr[4:0] = adresa registru
- addr[5] = selecteaza LSB (0) sau MSB (1) pentru registrele pe 16 biti

### Harta de memorie:
PERIOD (0x00) — 16b — R/W — defineste perioada semnalului PWM in cicluri  
COUNTER_EN (0x02) — 1b — R/W — activeaza numaratorul  
COMPARE1 (0x03) — 16b — R/W — prag pentru generarea PWM  
COMPARE2 (0x05) — 16b — R/W — al doilea prag in mod nealiniat  
COUNTER_RESET (0x07) — 1b — W — reseteaza contorul  
COUNTER_VAL (0x08) — 16b — R — citeste numaratorul curent  
PRESCALE (0x0A) — 8b — R/W — divide timpul incrementarii contorului  
UPNOTDOWN (0x0B) — 1b — R/W — directie numarare (1 up / 0 down)  
PWM_EN (0x0C) — 1b — R/W — activeaza iesirea PWM  
FUNCTIONS (0x0D) — 2b — R/W — configurare aliniere

### Semnale generate:
- period, compare1, compare2, prescale, pwm_en, upnotdown, en

Citirea COUNTER_VAL expune valoarea din counter.v.

----------

# 5. counter.v — Numarator cu prescaler

### Rol:  
Genereaza baza de timp pentru PWM, incrementand sau decrementand count_val in functie de prescale si directie.

### Comportament:
#### Daca count_reset = 1:
- count_val = 0
- prescaler resetat

#### Daca en = 0:
- contorul sta pe loc

### Prescaler:  
incrementare la fiecare (1 << prescale)

#### Exemple:  
prescale=0 → increment la fiecare ciclu clk  
prescale=1 → increment la 2 cicluri  
prescale=2 → increment la 4 cicluri

#### Directie:  
upnotdown=1 → numara in sus pana la period si revine la 0  
upnotdown=0 → numara in jos pana la 0 si revine la period

#### Output:  
count_val este transmis catre pwm_gen.

----------

# 6. pwm_gen.v — Generator semnal PWM

### Rol:  
Genereaza semnalul PWM in functie de count_val, valori de comparare si mod selectat.

### Control:  
pwm_en — enable global  
compare1 — prag de activare/dezactivare  
compare2 — doar in mod nealiniat  
functions[0] — aliniere (0 stanga, 1 dreapta)  
functions[1] — mod (0 aliniat, 1 nealiniat)

### Moduri PWM:
#### A) Mod aliniat (functions[1] = 0)
- aliniere la stanga: semnal 1 la start, cade la compare1
- aliniere la dreapta: semnal 0 la start, creste la compare1

#### B) Mod nealiniat (functions[1] = 1)
- semnal devine 1 la compare1
- cade la 0 la compare2  
  Valabil doar daca compare1 < compare2

Daca pwm_en=0, iesirea ramane blocata pe ultima valoare.

----------

# 7. Flux de programare prin SPI

#### Scriere LSB la COMPARE1:  
Byte 1: 1 0 000011 (Write, LSB, addr=3)  
Byte 2: valoare

#### Citire valoare counter:  
Byte 1: 0 0 001000 (Read, LSB, addr=8)  
Byte 2: dummy clock  
Masterul primeste raspunsul prin mosi.
