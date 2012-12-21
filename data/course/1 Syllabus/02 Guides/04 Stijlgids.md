# Stijlgids

Als nakijkers van jouw practicum merken we al snel of iets goed leesbaar is of niet. Begrijpen we snel wat je code doet? Ook in de praktijk blijkt het handig om goed leesbare code te schrijven. Voor een ander, die je code moet uitbreiden, of voor jezelf, als je een tijdje niet naar de code gekeken hebt.

Er is niet één correcte manier om je code te schrijven. Maar je kunt zeker een hoop fout (of laten we zeggen, onleesbaar) doen. Bij dit vak eisen we niet dat je je aan een vastgelegde stijl houdt, maar we raden je ten strengste aan om de conventies hieronder in acht te nemen, tenzij je jouw assistent kunt overtuigen dat jouw manier net zo goed is, of beter.

## Commentaar

Teveel commentaar is fout. Te weinig commentaar is fout. Maar hoeveel is dan goed? Een vuistregel is om je code op te delen in kleine blokken -- van elk een paar regels code -- en elk blok van een regel commentaar te voorzien.

Eén van de volgende twee vragen is meestal zeer relevant om te beantwoorden:

* Wat doet dit blok code?
* Waarom is het op deze manier geïmplementeerd?

###Voorbeeld

Variabelenamen leggen vaak al een beetje uit waarvoor ze dienen, en maken je code leesbaarder. En zo leg je dan uit wat je *precies* opslaat in de variabele:

    # compute student's average
    average = sum / QUIZZES + 0.5

Middenin je code schrijf je geen volzinnen, maar om het leesbaar te houden zet je wel netjes een spatie na de `#`.

Dus niet zo:

    #compute student's average
    # Compute student's average.

### Bovenaan je Python-bestand

Start altijd met de commentaarregels zoals voorgeschreven in de opdracht. Je mag ook nog iets toevoegen over de algehele werking van het programma; wat is het doel?

    # Problem Set 1
    # Name: Jane Lee
    # Collaborators: John Doe
    # Time: 1:30
    #
    # This program calculates the average values of a series
    # of numbers input by the user.
    
    ... your code goes here ...

### Lange regels commentaar

Let op de omschrijving van het programma in het voorbeeld hierboven. De omschrijving paste niet meer op één regel, dus is een nieuwe regel toegevoegd, ook weer beginnend met een `#`.

Vermijd regels langer dan 79 tekens; zo weet je zeker dat het op elk scherm en op papier goed weergegeven kan worden.

## Indentatie

Indentatie is het toevoegen van witruimte aan het begin van een regel om structuur zichtbaar te maken. Dat is in Python niet alleen voor de leesbaarheid: in veel gevallen is het in Python verplicht witruimte aan te brengen. Dit moet voor de leesbaarheid wel consequent gebeuren.

    def sum(x, y):
        result = x + y
        return result

Gebruik zoals hier minimaal **4 spaties** om het onderscheid duidelijk te houden.

### Tabs en spaties

Gebruik voor witruimte alleen spaties of alleen tabs, en niet door elkaar. Een tab wordt namelijk op diverse computers als een verschillend aantal spaties weergegeven. Als het er netjes zo uitziet zoals hierboven, kan het er op een andere computer zo uitzien:

    def sum(x, y):
        result = x + y     # vier spaties
            return result  # 1 tab is hier 8 spaties geworden

Bovendien zal de code dan niet meer goed werken in Python.

Naarmater je functies wat langer worden leidt dit tot grotere onleesbaarheid door inconsequentie. Gebruik dus bij voorkeur precies 4 spaties, zoals de conventie is in Python-code.

### Verplichte indentatie

In Python kun je er doorgaans vanuit gaan dat na elke regel eindigend op een `:`, de volgende regel met een extra niveau indentatie moet worden geschreven. Dat geldt voor alle volgende regels die ondergeschikt zijn aan de regel die met een `:` eindigt:

    # onderstaande functie bestaat uit vier regels of instructies
    def sum(arrayOfNumbers):
        result = 0
        # onderstaande for-loop bestaat uit één regel die herhaald wordt
        for number in arrayOfNumbers:
            result = result + number
        return result

## Naamgeving

Veel elementen in je Python-programma kunnen een *naam* krijgen, waaronder functies en variabelen.

### Functies

Functienamen mogen zo lang zijn als je wilt, maar moeten geschreven worden met underscores tussen de woorden:

    def user_average_this_year():

### Variabelen

Variabelenamen zijn doorgaans wat korter dan functienamen, maar één of twee woorden bevordert de leesbaarheid. Er is geen enkele reden om namen af te korten!

Vanzelfsprekend kun je gebruikelijke symboliek uit de wiskunde overnemen als je een wiskundig probleem aanpakt. De meeste andere probleemdomeinen kennen dergelijke symboliek niet en vereisen langere namen.

    d = 0.002                   # delta voor een benaderingsfunctie
    resterend_pensioen -= 2000  # geen commentaar nodig

## Andere witruimte

Net als bij andere media waar teksten geschreven worden om te lezen, voegen we bij code vaak witruimte toe om te leesbaarheid te vergroten. Indentatie is daar een voorbeeld van, maar het kan op nog een aantal manieren.

### Witregels tussen blokken en functies

Als je je code opdeelt in kleine blokken, met bijvoorbeeld een regeltjes commentaar erboven, voeg je boven dat commentaar een witregel toe.

	# user input
	user_input = input("Please enter a number: ")
	
	# calculations - uses a complex loop to handle special cases
	while(user_input > 0):
		user_input -= 1
	
	# output - might not print zero if user put in a float
	print user_input

### Spaties rondom operators

Operators zijn zeer compact genaamde functies, zoals `+`, `==`, `%` of `?`. Code die gebruikt maakt van operators is leesbaar te houden door een spatie in te voegen vóór en achter de operator:

    i = i + 1
    submitted += 1
    x = x * 2 - 1
    hypot2 = x * x + y * y
    c = (a + b) * (a - b)
