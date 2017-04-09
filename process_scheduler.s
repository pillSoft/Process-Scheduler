# Salani Lorenzo: lorenzo.salani@stud.unifi.it
# Fagioli Giulio: giulio.fagioli@stud.unifi.it	
# Buonanno Cecilia: cecilia.buonanno@stud.unifi.it
.data
   	jump_table: .space 28		# jump table array a 7 word che verra' instanziata dal main con gli indirizzi delle label per chiamarele corrispondenti procedure
	schedulingType : .word 0	# Word che contiene la modalita' di scheduling
	id: 	  .word 0		# Word che contiene l'id del prossimo record che andremo a memorizzare
	
	#Stringhe
	#Menu
	stringaBenvenuto: .asciiz "Benvenuto nel simulatore di scheduler di processi.\n"
	stringaMenu : .asciiz "1) Inserisci un nuovo Task\n2) Esegui primo task in testa alla coda\n3) Esegui il task con id (Richiede l'id)\n4) Elimina il task con id (Richiede l'id)\n5) Modificare priorita' del task con id (Richiede l'id)\n6) Cambia modalita' di scheduing  \n7) Esci dal programma\n"
   	inserimento:.asciiz "Inserisci un numero da 1 a 7\n"
	#Inserimento
	inserisciPriorita:   .asciiz "Inserisci la priorita' del task (fra 0 e 9) \n"
	inserisciNome:   .asciiz "Inserisci il nome del task (max 8 caratteri)\n"
	inserisciEsecuzione:   .asciiz "Inserisci le esecuzioni necessarie per il completamento del task (fra 1 e 99)\n"
	#Esecuzione task
	taskRimosso: .asciiz "Esecuzioni rimanenti 0, il task e' stato rimosso.\n"	
	#Cambia scheduling
	politicaUtilizzata: .asciiz "Politica utilizzata:"
	schedulingPriorita:   .asciiz "Scheduling su Priorita'\n"
	schedulingEsecuzioni:  .asciiz "Scheduling su Esecuzioni rimanenti\n"
	cambiaScheduling:	 .asciiz "Vuoi cambiare la politica di scheduling utilizzata? (y/n) \n"
	politicaCambiata : .asciiz "\nPolitica cambiata.\n"
	#Ricerca id
	inserisciId : .asciiz "Inserisci l'id:"
	idNonTrovato: .asciiz "Id non trovato.\n"
	#Modifica priorita'
	priorita: .asciiz "Priorita': "
	cambiaPriorita: .asciiz "Inserisci la nuova priorita': "
	#Varie
	operazioneNonConsentita:  .asciiz "Operazione consentita con almeno un task nella coda.\n"
	operazioneOk:  .asciiz "Operazione effettuata con successo.\n"
   	erroreScelta:.asciiz "Il numero inserito non era compreso tra 1 e 7\n"
   	fine:.asciiz "Termine simulatore\n\n"
   	#Stringhe tabella
   	spazio:   .asciiz " "
   	stanga: .asciiz "|"
	stangaFineTab: .asciiz "|\n"
	inizioStringaDati: .asciiz "|  "
	fineStringaDati: .asciiz "  |"
	fineStringaDatiDoppia: .asciiz "   |"
	primaLineaTab: .asciiz "+------+------------+-------------+-----------------------+\n|  ID  |  PRIORITA' |  NOME TASK  |  ESECUZION. RIMANENTI |\n+------+------------+-------------+-----------------------+\n"
	ultimaLienaTab: .asciiz "+------+------------+-------------+-----------------------+\n"
   	
   	# $t8 = $t9 = 0 coda vuota
   	# $t8 = $t9 coda con 1 elemento
   	# $t8 != $t9 coda piena
   	
.text

.globl main
main:
# Prepara la jump_table con gli indirizzi delle case actions
	la $t1, jump_table	# Caricamento indirizzo jumptable 
	la $t0, inserimentoTask # Caricamento indirizzo procedura inserimentoTask 
	sw $t0, 0($t1)		
	la $t0, eseguiTask	# Caricamento indirizzo procedura eseguiTask  
	sw $t0, 4($t1)
    	la $t0, eseguiTaskId	# Caricamento indirizzo procedura eseguiTaskId 
	sw $t0, 8($t1)
	la $t0, rimuoviTaskById	# Caricamento indirizzo procedura rimuoviTaskById 
	sw $t0, 12($t1)
	la $t0, modificaPriorita# Caricamento indirizzo procedura modificaPriorita 
	sw $t0, 16($t1)
	la $t0, modificaScheduling# Caricamento indirizzo procedura modificaScheduling 
	sw $t0, 20($t1)
    	la $t0, exit		# Caricamento indirizzo procedura exit 
	sw $t0, 24($t1)

	la $a0,stringaBenvenuto	# Cariamento stringa di benvenuto in $a0 per essere stampata
	li $v0,4		# Syscall stampa stringa
	syscall
	
printMenu:
	la $a0,stringaMenu	# Cariamento stringa del menu' in $a0 per essere stampata
	li $v0,4		# Syscall stampa stringa
	syscall
# Inserimento del numero per effettuare la scelta
sceltaMenu:
	li $v0,4		# Syscall stampa stringa 
        la $a0, inserimento 	# Cariamento stringa inserimento
	syscall 		
	
      	li $v0, 5		# Syscall inserimento intero 
	syscall
	
	move $t2, $v0   	# Copia della scelta in $t2 

	sle  $t0, $t2, $zero	# Nel caso in cui la scelta sia minore di 0 imposta $t1 a 1
	bne  $t0, $zero, errScelta # Se scelta minore di 1 si salta all'etichetta di errore 
	li   $t0,7		# Caricamento di 7 in $t0 per il confronto successivo
	sle   $t0, $t2, $t0	# Nel caso in cui la scelta sia minore di 7 imposta $t1 a 1
	beq  $t0, $zero, errScelta 	# Se scelta maggiore di 7 si salta all'etichetta di errore 
# Gestione della scelta 
branch_case:
	blt $t2,2,continuaBranch	#Se e' effettuata una scelta che richiede almeno un task inserito si richiede nuovamente la scelta
	bgt $t2,5,continuaBranch
	
	bne $t8,$t9,continuaBranch	# Se i due puntatori testa e coda non sono uguali 
	bne $t8,$zero,continuaBranch	# e non sono uguali a 0 saltiamo a continuaBranch
	
	li $v0,4			# Syscall stampa stringa 
        la $a0, operazioneNonConsentita # Cariamento stringa inserimento
	syscall 
	
	j sceltaMenu 			# Se $t8 = $t9 = 0 saltiamo a sceltaMenu
	
continuaBranch:
	
	la $t1, jump_table	# Cariamento indirizzo jump table
	addi $t2, $t2, -1 	# Si sottrae 1 dalla scelta perche' prima azione nella jump table (in posizione 0) corrisponde alla prima scelta del case
	add $t0, $t2, $t2	# Calcolo (scelta) * 2
	add $t0, $t0, $t0 	# Calcolo (scelta) * 4
	add $t0, $t0, $t1 	# Somma dell'indirizzo della jump_table l'offset calcolato 
	lw $t0, 0($t0)    	# $t0 = indirizzo a cui devo saltare
	jalr $t0 		# Salto all'indirizzo calcolato

	beq $t8,$t9,stampaRecord	# Se i registri $t8 (testa) e $t9 (coda) sono uguali significa che l'ordinamento non e' necessario

	jal sortById		# Richiamo della funzione sortById che ordina lo heap in modo decrescente rispetto all'id
	
	lw $t0, schedulingType	# Caricamento della politica di scheduling utilizzata
	
	beq $t0,1,ordinamentoEsecuzioni	# Se il tipo di scheduling e' 1 si esegue un ordinamento per esecuzioni rimanenti
	jal sortByPriorita	# Chiamata del sort per Priorita'
	
	j stampaRecord		# Salto nuovamente alla scelta 
	
	ordinamentoEsecuzioni:		
	jal sortByEsecuzioni	# Chiamata del sort per Esecuzioni rimanenti

	stampaRecord:
	bne $t8,$t9,continuaStampa	# Se i due puntatori testa e coda non sono uguali 
	bne $t8,$zero,continuaStampa	# e non sono uguali a 0 saltiamo a printMenu
	j printMenu
	continuaStampa:
	jal stampaTabella	# Stampa della tabella con tutti i record
	
	j printMenu		# Salto nuovamente alla scelta  

#Case 1 : Funzione che permette di inserire un task
inserimentoTask:
# Allocazione di 28 byte per il record da inserire 
	li $v0, 9		# Syscall allocazione memria nell'heap	
	li $a0, 28		# Caricamento del numero di bytes da allocare, indirizzo del record in $v0
	syscall  
	move $s0, $v0 		# Spostamento dell'indirizzo in $v0
# Inserimenti
	sw $zero, 0($s0)	# Azzeramento Campo del puntatore all'elemento precedente
# Inserimento id
	lw $t0, id		# Caricamento word id, che contiene il prossimo id da utilizzare 	
	sw $t0, 4($s0)  	# Salvataggio dell'id nel secondo campo del record

	addi $t0, $t0, 1	# Aumento dell'id di 1
	sw $t0, id		# Memorizzazione nuovo id nella word 
# Inserimento nome	
	li $v0,4		# Syscall stampa stringa
	la $a0, inserisciNome 	# Cariamento stringa
	syscall 

	li $a1, 9		# Massimo numero di caratteri inseribile, compreso il terminatore 
	la $a0, 8($s0)		# Caricamento dell'indirizzo dove salvare la stringa (terzo e quarto campo della stringa)
	li $v0, 8 		# Syscall lettura stringa 
	syscall 
	
# Inserimento priorita'
	li $v0,4		# Syscall stampa stringa
	la $a0, inserisciPriorita# Cariamento stringa
	syscall

reinserisciPriorita:
	li $v0, 5		# Syscall inserimento intero, risultato in $v0
	syscall 

	bgt $v0,9, reinserisciPriorita	# Nel caso in cui non si inserisca una priorita' fra 0 e 9 essa verra' richiesta
      	blt $v0,0, reinserisciPriorita
      	
	sw $v0, 16($s0) 	# Salvataggio della priorita' nel quinto campo del record
        
#Esecuzioni   	           	           	
	li $v0,4		# Syscall stampa stringa
	la $a0, inserisciEsecuzione # Cariamento stringa
	syscall

reinserisciEsecuzione:
	li $v0, 5		# Syscall inserimento intero, risultato in $v0
	syscall 
	bgt $v0,99, reinserisciEsecuzione # Nel caso in cui non si inserisca un numero di esecuzioni fra 1 e 99 essa verra' richiesta
	blt $v0,1, reinserisciEsecuzione
             
	sw $v0, 20($s0)  	# Salvataggio del numero di esecuzioni nel sesto campo del record
	
	sw $zero, 24($s0)  	# Salvataggio dellla priorita' nel quinto campo del record
# Modifica puntatori record successivo e precedente
	bne $t8, $zero, linkLast# Se la coda non e' vuota si salta all'etichetta linkLast
	move $t8, $s0          	# Se la coda e' vuota impostiamo $t8 e $t9 all'indirizzo dell'unico record
	move $t9, $s0		
	j fineInserimento	# Salto alla fine dell'inserimento di un record
linkLast: 		
	sw $s0, 24($t9)         # Si memorizza l'indirizzo del nuovo record nel'ultimo campo dell'ultimo record
	sw $t9, 0($s0)		# Si memorizza l'indirizzo dell'ultimo record nel primo campo del nuovo record 
	move $t9, $s0           # L'ultimo record prende l'indirizzo del nuovo record
fineInserimento:
	li $v0,4		# Syscall stampa stringa
	la $a0, operazioneOk 	# Caricamento stringa 
	syscall

	jr $ra			# Ritorno al chiamante			
	
#Case 2: Funzione di esecuzione del task in testa
eseguiTask:

	lw $t1, 20($t9) 	# Salvataggio in $t1 del numero di esecuzioni del task in testa($t9)
	addi $t1,$t1,-1 	# Decremento del suo numero di esecuzioni

	bne $t1, $zero, mantieniTask	# Se il numero di esecuzioni rimanenti dopo il decremento non e' zero vado all'etichetta mantieniTask
# Se il numero di esecuzioni rimanenti e' 0 dopo l'ultima esecuzione rimuovo il task a quell'indirizzo
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti
	
	move $a0, $t9 		# Caricamento dell'indirizzo da eliminare in $a0
	jal rimuoviTask		# Chiamata alla procedura per rimuovere un record passando il suo indirizzo per parametro

	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	li $v0,4		# Syscall stampa stringa
	la $a0, taskRimosso 	# Caricamento stringa 
	syscall

	jr $ra			# Ritorno al chiamante			
	
mantieniTask:
	sw $t1, 20($t9) 	# Se il task non e' stato rimosso si memorizza il nuovo numero di esecuzioni nel sesto campo dell'elemento in testa
	
	li $v0,4		# Syscall stampa stringa
	la $a0, operazioneOk 	# Caricamento stringa 
	syscall

	jr $ra			# Ritorno al chiamante			


#Case 3
eseguiTaskId:

	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	li $v0,4		# Syscall stampa stringa
	la $a0, inserisciId	# Caricamento stringa 
	syscall

	li $v0, 5		# Syscall inserimento intero
	syscall 

	move $a0,$v0		# Caricamento id da ricercare in $a0 	
	jal ricercaId		# Chiamata alla funzione che restituisce l'indirizzo corrispondente al record con l'id cercato

	beq $v0,-1, errIdRicercaNonTrovato	# Id non trovato uscita dalla funzione
				
	move $t0,$v0		# Salvataggio indirizzo record da eseguire in $t0
	lw $t1, 20($t0) 	# Salvataggio in $t1 del numero di esecuzioni del task cercato
	addi $t1,$t1,-1 	# Decremento del suo numero di esecuzioni

	bne $t1, $zero, mantieniTaskId	# Se il numero di esecuzioni rimanenti dopo il decremento non e' zero vado all'etichetta mantieniTask
	move $a0, $t0 		# Caricamento dell'indirizzo da eliminare in $a0
	jal rimuoviTask		# Chiamata alla procedura per rimuovere un record passando il suo indirizzo per parametro
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	jr $ra			# Ritorno al chiamante			
mantieniTaskId:
	sw $t1, 20($t0) 	# Se il task non e' stato rimosso si memorizza il nuovo numero di esecuzioni nel sesto campo dell'elemento in test
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	li $v0,4		# Syscall stampa stringa
	la $a0, operazioneOk 	# Caricamento stringa 
	syscall

	jr $ra			# Ritorno al chiamante		
	
errIdRicercaNonTrovato:
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	li $v0,4		# Syscall stampa stringa
	la $a0, idNonTrovato	# Caricamento stringa
	syscall
	jr $ra			# Ritorno al chiamante	

#Case 4
rimuoviTaskById:

	li $v0,4		# Syscall stampa stringa
	la $a0, inserisciId	# Caricamento stringa
	syscall

	li $v0, 5		# Syscall inserimento intero
	syscall 

	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	move $a0,$v0		# Caricamento dell'indirizzo da ricercare in $a0
	jal ricercaId		# Chiamata alla funzione che restituisce l'indirizzo corrispondente al record con l'id cercato

	beq $v0,-1, errIdRicercaNonTrovato	# Id non trovato uscita dalla funzione

	move $a0,$v0		# Salvataggio indirizzo record da eliminare in $a0
	jal rimuoviTask		# Chiamata alla procedura per rimuovere un record passando il suo indirizzo per parametro

	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer

	li $v0,4		# Syscall stampa stringa
	la $a0, operazioneOk	# Caricamento stringa
	syscall

	jr $ra			# Ritorno al chiamante

#Case 5
#Funzione che richiede l'id e permette la modifica della priorita del task
modificaPriorita:
	li $v0,4		# Syscall stampa stringa
	la $a0, inserisciId	# Caricamento stringa
	syscall

	li $v0, 5		# Syscall inserimento intero
	syscall 

	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	move $a0,$v0		# Caricamento dell'indirizzo da ricercare in $a0
	jal ricercaId		# Chiamata alla funzione che restituisce l'indirizzo corrispondente al record con l'id cercato

	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer

	beq $v0,-1, errIdRicercaNonTrovato	# Id non trovato uscita dalla funzione, altrimenti si chiede la priorita' nuova
	move $t0,$v0		# Caricamento in $t0 dell'indirizzo del record di cui cambiare la priorita'
											
	li $v0,4		# Syscall stampa stringa
	la $a0, cambiaPriorita	# Caricamento stringa
	syscall
rimodificaPriorita:
	li $v0, 5		# Syscall inserimento intero
	syscall 
	
	bgt $v0,9, reinserisciPriorita	# Nel caso in cui non si inserisca una priorita' fra 0 e 9 essa verra' richiesta
      	blt $v0,0, reinserisciPriorita	
      	      
	sw $v0, 16($t0) 	# Salvataggio nuova priorita' nel quinto campo del record

	li $v0,4		# Syscall stampa stringa
	la $a0, operazioneOk	# Caricamento stringa
	syscall

	jr $ra			# Ritorno al chiamante

#Case 6
modificaScheduling:
	li $v0,4			# Syscall stampa stringa
	la $a0, politicaUtilizzata	# Caricamento stringa
	syscall
	lw $t0, schedulingType		# Caricamento in $t0 della word contenente la politica di schedulig utilizzata al momento
	beq $t0, 0, schedPriorita	# Se e' 0 si salta all'etichetta schedPriorita

	li $v0,4			# Syscall stampa stringa
	la $a0, schedulingEsecuzioni	# Caricamento stringa
	syscall
	j continuaScheduling			
schedPriorita:
	li $v0,4			# Syscall stampa stringa
	la $a0, schedulingPriorita	# Caricamento stringa
	syscall 
continuaScheduling:
	li $v0,4		# Syscall stampa stringa
	la $a0, cambiaScheduling# Caricamento stringa
	syscall 

	li $v0, 12		# Syscall lettura carattere (y/n)	
	syscall 

	beq $v0,'y',cambio	# Se e' stata inserita una y si cambia il tipo di scheduling
	j fineCambio		# altrimenti essa non verra' cambiata
cambio:
	beq $t0,0,setTo1	# Se $t0 e' uguale a 0 verra' settato ad 1 saltando all'etichetta setTo1
	li $t0,0		# Se $t0 e' uguale a 1 verra' settato ad 0
	sw $t0,schedulingType	# E verra' aggiornata la word schedulingType con il nuovo valore
	j fineCambio			
setTo1:			
	li $t0,1		# Se $t0 e' uguale a 0 verra' settato ad 1
	sw $t0,schedulingType 	# E verra' aggiornata la word schedulingType con il nuovo valore
	li $v0,4		# Syscall stampa stringa
	la $a0, politicaCambiata# Caricamento stringa di cambiamento della politica
	syscall 
fineCambio:
	jr $ra			# Ritorno al chiamante


#Case 7
exit: # stampa messaggio di uscita e esce
	li $v0,4		# Syscall stampa stringa
	la $a0, fine		# Caricamento stringa di fine programma
	syscall
	
	li $v0, 10		# Syscall termine programma
      	syscall


#Funzione che ricerca un id e lo restituisce, se non lo trova restituisce -1
#Parametro $a0 id da ricercare
#Valore di ritorno: $v0, indirizzo del record con l'id cercato
ricercaId:
	move $t0,$t8		# Caricamento indirizzo della testa in $t0
loopRicercaId:
	lw $t1, 4($t0)		# Caricamento id dell'elemento puntato da $t0 in $t1
	beq $t1, $a0, fineRicerca# Se l'elemento e' uguale all'elemento passato come parametro la ricerca e' finita
	
	lw $t2, 24($t0)		# Caricamento indirizzo successivo in $t2
	beq $t2, $zero, fineIdNonTrovato# Se l'indirizzo successivo e' zero l'id non e' stato trovato
			
	lw $t0, 24($t0)		# $t0 prende l'elemento successivo della coda
	j loopRicercaId 	# Salto all'etichtta per eseguire un altro ciclo
fineRicerca:
	move $v0, $t0		# Spostamento nel registro $v0 dell'indirizzo del record cercato	
	jr $ra			# Ritorno al chiamante
fineIdNonTrovato:
	li $v0,-1		# Se nessun id e' stato trovato restiruisce -1
	jr $ra			# Ritorno al chiamante


#Funzione rimuove il task corrispondente all'indirizzo passato come parametro
#Parametro $a0 indirizzo da eliminare
rimuoviTask:
	move $t0,$a0		# Caricamento indirizzo del task da rimuovere in $t0
#Copio il record primo nel record da eliminare
	lw  $t1, 4($t8) 	# Salvataggio di ogni campo del record in testa in $t1
	sw $t1, 4($t0)		# Copia di $t1 nel campo corrispondente del record da eliminare
	lw  $t1, 12($t8)
	sw $t1, 12($t0)
	lw  $t1, 16($t8)
	sw $t1, 16($t0)
	lw  $t1, 20($t8)
	sw $t1, 20($t0)
#azzerramento del campi del record 
	li  $t1, 0		# Caricamento di 0 in $t1 per azzerare i campi
	move $t2, $t8		# Copia dell'indirizzo della testa in $t2

	beq $t8, $t9, nessunElemento	# Se la coda contiene un solo elemento salto si deve cancellare senza aggiornare i puntatori
	lw  $t8, 24($t8)	# Se la coda contiene piu' elementi si fa puntare la testa al successivo elemento
	sw  $t1, 0($t8)		# e si azzera il primo campo di essa 

	j piuElementi			
nessunElemento:			
	move $t8,$zero		# Azzeramento testa e coda perche' non ha elementi,
	move $t9,$zero		# non eseguito nel caso in cui la coda abbia piu' elementi

piuElementi:			
	sw $t1, 0($t2)		# Azzeramento campi del primo record (testa precedente)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)
	sw $t1, 20($t2)
	sw $t1, 24($t2)
	
	jr $ra			# Ritorno al chiamante


#Ordinamenti
#Sort decrescente per id
sortById:
ricerca:
	move $t0, $t8		# Caricamento indirizzo della testa in $t0
#Ricerca del massimo fra $t0 e la fine della coda
ricercaMassimo:	
	lw $t1, 24($t0)		# Caricamento in $t1 dell'indirizzo del record successivo a $t0
	beq $t1, $zero, fineRicercaMassimo# Ad ogni ciclo se $t1 e' uguale a 0 abbiamo trovato il massimo
	lw $t2, 4($t0)		# Caricamento in $t2 dell'id dell'elemento puntato da $t0
	move $t4,$t0		# Spostamento in $t4 di $t0 per non modificarlo
loopRicerca:
	beq $t1, $zero, scambi	# Se  t1 == 0 si e' raggiunta la fine della lista e si possono effettuare gli scambi
	lw $t3, 4($t1)		# Caricamento id in $t3
	bge $t2, $t3,continua	# Se l'elemento che era il massimo ($t2) e' piu' grande dell'elemento corrente si salta all'etichetta continua
	move $t2,$t3		# altrimenti si scambiano i valori
	move $t4,$t1		# Si memorizza in $t4 il puntatore all'elemento piu' grande
continua:
	lw $t1, 24($t1)		# Scorrimento di $t1 all'elemento successivo	
	j loopRicerca		# Salta all'inizio del ciclo per cercare il massimo
scambi:
#Quando abbiamo trovato il valore massimo(puntato da $t4) 
#si effettuano gli scambi degli elementi adiacenti per portarlo nella posizione puntata da $t0
	lw $t5, 0($t4)		# Caricamento dell'elemento precedente a $t4 in $t5
	bgt $t0, $t5, esci	# Se l'indirizzo di $t0 e' maggiore di $t5 significa che l'elemento e' gia' al suo posto
	
scambiaAdiacenti:
	lw $t6, 4($t4)		# Caricamento in $t6 dell'id di $t4
	lw $t7, 4($t5)		# Caricamento in $t6 dell'id di $t5
	beq $t6, $t7, nonScambiare# Lo scambio non viene effettuato se gli id da scambiare sono uguali
	
	lw  $t6, 4($t5)		# altrimenti scambio di tutti i valori dei due record adiacenti 
	lw $t7, 4($t4)
	sw $t6, 4($t4)
	sw $t7, 4($t5)
	
	lw  $t6, 8($t5)
	lw $t7, 8($t4)
	sw $t6, 8($t4)
	sw $t7, 8($t5)
	
	lw  $t6, 12($t5)
	lw $t7, 12($t4)
	sw $t6, 12($t4)
	sw $t7, 12($t5)
	
	lw  $t6, 16($t5)
	lw $t7, 16($t4)
	sw $t6, 16($t4)
	sw $t7, 16($t5)
	
	lw  $t6, 20($t5)
	lw $t7, 20($t4)
	sw $t6, 20($t4)
	sw $t7, 20($t5)
	
nonScambiare:			
	lw $t4, 0($t4)		# Scorrimento di $t4 all'elemento precedente	
	lw $t5, 0($t4)		# Scorrimento di $t5 all'elemento precedente di $t4
	bgt $t0,$t5, esci	# Se l'indirizzo di $t0 e' maggiore di $t5 significa che l'elemento e' gia' al suo posto
	j scambiaAdiacenti	# Salta all'inizio del ciclo effetuare nuovamente uno scambio
	
esci:
	lw $t0, 24($t0)		# Scorrimento di $t0 all'elemento successivo	
	j ricercaMassimo 	# Salta all'inizio del ciclo per cercare il massimo 
	
fineRicercaMassimo:
	jr $ra			# Ritorno al chiamante
	


#Sort decrescente per priorita'
sortByPriorita:
ricercaP:
	move $t0, $t8		# Caricamento indirizzo della testa in $t0
#Ricerca del massimo fra $t0 e la fine della coda
ricercaMassimoP:
	lw $t1, 24($t0)		# Caricamento in $t1 dell'indirizzo del record successivo a $t0
	beq $t1, $zero, fineRicercaMassimoP# Ad ogni ciclo se $t1 e' uguale a 0 abbiamo trovato il massimo
	lw $t2, 16($t0)		# Caricamento in $t2 della priorita' dell'elemento puntato da $t0
	move $t4,$t0		# Spostamento in $t4 di $t0 per non modificarlo
loopRicercaP:
	beq $t1, $zero, scambiP	# Se  t1 == 0 si e' raggiunta la fine della lista e si possono effettuare gli scambi
		lw $t3, 16($t1)	# Caricamento priorita' in $t3
	bge $t2, $t3,continuaP	# Se l'elemento che era il massimo ($t2) e' piu' grande dell'elemento corrente si salta all'etichetta continua
	move $t2,$t3		# altrimenti si scambiano i valori
	move $t4,$t1		# Si memorizza in $t4 il puntatore all'elemento piu' grande
continuaP:
	lw $t1, 24($t1)		# Scorrimento di $t1 all'elemento successivo	
	j loopRicercaP		# Salta all'inizio del ciclo per cercare il massimo
scambiP:
#Quando abbiamo trovato il valore massimo(puntato da $t4) 
#si effettuano gli scambi degli elementi adiacenti per portarlo nella posizione puntata da $t0
	lw $t5, 0($t4)		# Caricamento dell'elemento precedente a $t4 in $t5
	bgt $t0, $t5, esciP	# Se l'indirizzo di $t0 e' maggiore di $t5 significa che l'elemento e' gia' al suo posto
	
scambiaAdiacentiP:
	lw $t6, 16($t4)		# Caricamento in $t6 della priorita' di $t4
	lw $t7, 16($t5)		# Caricamento in $t6 della priorita' di $t5
	beq $t6, $t7, nonScambiareP# Lo scambio non viene effettuato se l priorita' da scambiare e' uguale 
	
	lw  $t6, 4($t5)		# altrimenti scambio di tutti i valori dei due record adiacenti 
	lw $t7, 4($t4)
	sw $t6, 4($t4)
	sw $t7, 4($t5)
	
	lw  $t6, 8($t5)
	lw $t7, 8($t4)
	sw $t6, 8($t4)
	sw $t7, 8($t5)
	
	lw  $t6, 12($t5)
	lw $t7, 12($t4)
	sw $t6, 12($t4)
	sw $t7, 12($t5)
	
	lw  $t6, 16($t5)
	lw $t7, 16($t4)
	sw $t6, 16($t4)
	sw $t7, 16($t5)
	
	lw  $t6, 20($t5)
	lw $t7, 20($t4)
	sw $t6, 20($t4)
	sw $t7, 20($t5)
	
nonScambiareP:			
	lw $t4, 0($t4)		# Scorrimento di $t4 all'elemento precedente	
	lw $t5, 0($t4)		# Scorrimento di $t5 all'elemento precedente di $t4
	bgt $t0,$t5, esciP	# Se l'indirizzo di $t0 e' maggiore di $t5 significa che l'elemento e' gia' al suo posto
	j scambiaAdiacentiP	# Salta all'inizio del ciclo effetuare nuovamente uno scambio
	
esciP:
	lw $t0, 24($t0)		# Scorrimento di $t0 all'elemento successivo	
	j ricercaMassimoP 	# Salta all'inizio del ciclo per cercare il massimo 
	
fineRicercaMassimoP:
	jr $ra			# Ritorno al chiamante
	

#Sort crescente per Esecuzioni rimanenti
sortByEsecuzioni:
ricercaE:
	move $t0, $t8		# Caricamento indirizzo della testa in $t0
#Ricerca del minimo fra $t0 e la fine della coda
ricercaMinimoE:
	lw $t1, 24($t0)		# Caricamento in $t1 dell'indirizzo del record successivo a $t0
	beq $t1, $zero, fineRicercaMinimoE# Ad ogni ciclo se $t1 e' uguale a 0 abbiamo trovato il minimo
	lw $t2, 20($t0)		# Caricamento in $t2 delle esecuzioni rimanenti dell'elemento puntato da $t0
	move $t4,$t0		# Spostamento in $t4 di $t0 per non modificarlo
loopRicercaE:
	beq $t1, $zero, scambiE	# Se  t1 == 0 si e' raggiunta la fine della lista e si possono effettuare gli scambi
	lw $t3, 20($t1)		# Caricamento esecuzioni rimanenti in $t3
	ble $t2, $t3,continuaE	# Se l'elemento che era il minimo ($t2) e' piu' piccolo dell'elemento corrente si salta all'etichetta continua
	move $t2,$t3		# altrimenti si scambiano i valori
	move $t4,$t1		# Si memorizza in $t4 il puntatore all'elemento piu' piccolo
continuaE:
	lw $t1, 24($t1)		# Scorrimento di $t1 all'elemento successivo
	j loopRicercaE		# Salta all'inizio del ciclo per cercare il minimo
scambiE:
#Quando abbiamo trovato il valore minimo(puntato da $t4) 
#si effettuano gli scambi degli elementi adiacenti per portarlo nella posizione puntata da $t0
	lw $t5, 0($t4)		# Caricamento dell'elemento precedente a $t4 in $t5
	bgt $t0, $t5, esciE	# Se l'indirizzo di $t0 e' maggiore di $t5 significa che l'elemento e' gia' al suo posto
scambiaAdiacentiE:

	lw $t6, 20($t4)		# Caricamento in $t6 delle esecuzioni rimanenti di $t4
	lw $t7, 20($t5)		# Caricamento in $t6 delle esecuzioni rimanenti di $t5
	beq $t6, $t7, nonScambiareP# Lo scambio non viene effettuato se il numero di esecuzioni rimanenti da scambiare e' uguale 

	lw  $t6, 4($t5)		# altrimenti scambio di tutti i valori dei due record adiacenti 
	lw $t7, 4($t4)
	sw $t6, 4($t4)
	sw $t7, 4($t5)
	
	lw  $t6, 8($t5)
	lw $t7, 8($t4)
	sw $t6, 8($t4)
	sw $t7, 8($t5)
	
	lw  $t6, 12($t5)
	lw $t7, 12($t4)
	sw $t6, 12($t4)
	sw $t7, 12($t5)
	
	lw  $t6, 16($t5)
	lw $t7, 16($t4)
	sw $t6, 16($t4)
	sw $t7, 16($t5)

	lw  $t6, 20($t5)
	lw $t7, 20($t4)
	sw $t6, 20($t4)
	sw $t7, 20($t5)

nonScambiareE:
	lw $t4, 0($t4)		# Scorrimento di $t4 all'elemento precedente	
	lw $t5, 0($t4)		# Scorrimento di $t5 all'elemento precedente di $t4
	bgt $t0,$t5, esciE	# Se l'indirizzo di $t0 e' maggiore di $t5 significa che l'elemento e' gia' al suo posto
	j scambiaAdiacentiE

esciE:
	lw $t0, 24($t0)		# Scorrimento di $t0 all'elemento successivo	
	j ricercaMinimoE	# Salta all'inizio del ciclo per cercare il massimo 

fineRicercaMinimoE:
	jr $ra			# Ritorno al chiamante


#Funzione utilizzata per stampare la tabella contenente tutte le informazioni sui task
stampaTabella:		
	li $v0, 4		# Syscall stampa stringa
	la $a0, primaLineaTab	# Caricamento stringa
	syscall			

stampaRighe:
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	move $t0,$t8		# Memorizza il valore del puntatore alla testa della coda in $t0
loopStampaRighe:		# Inizio della stampa della tabella 
#Stampa ID Task
	li $v0,4		# Syscall stampa stringa
	la $a0,inizioStringaDati# Stampa della prima linea della tabella 
	syscall
	
	li $v0,1		# Syscall stampa intero
	lw $a0, 4($t0)		# Caricamento in $a0 dell'Id del task peer stamparlo	
	syscall			
	
	slti $t4,$a0,10		# Controllo il numero di cifre del valore ID , questo per capire quanti spazi dovra' stampare 
				# ( se $a0 < 10 mette 1 in $t4 altrimenti 0)
	beq $t4,1,idAUnaCifra	# Se $t4 e' uguale a 1 salto all'etichetta IdAUnaCifra 
	li $v0,4		# Syscall stampa stringa
	la $a0,fineStringaDati	# Caricamento stringa
	syscall
idAUnaCifra:			# Se l'ID e' composto da una sola cifra stampo una Stringa composta da due Spazi e un barra
	li $v0,4		# Syscall stampa stringa
	la $a0,fineStringaDatiDoppia# Caricamento stringa
	syscall
#Stampa Proprieta'† del Task
	li $a0,6 		# Memorizzo 6 in $a0,  sara'† utilizzato come argomento della funzione StampaNSpazi 
	jal stampaNSpazi		# Richiamando stampaNSpazi si stampera' un numero di spazi pari ad $a0
	
	li $v0,1		# Syscall stampa intero
	lw $a0, 16($t0)		# Memorizzo in $a0 la priorita'†del Task
	syscall			

	li $a0,5		# Memorizzo 5 in $a0, sara'† utilizzato come argomento della funzione StampaNSpazi 
	jal stampaNSpazi	# Richiamando stampaNSpazi si stampera' un numero di spazi pari ad $a
	
	li $v0,4		# Syscall stampa stringa
	la $a0,stanga		# Caricamento stringa
	syscall			

# Stampa Nome del Task
	li $a0,2 		# Memorizzo 5 in $a0, sara'† utilizzato come argomento della funzione StampaNSpazi 
	jal stampaNSpazi	# Richiamando stampaNSpazi si stampera' un numero di spazi pari ad $a
# Stampa del nome per caratteri
	la $s0, 8($t0)		# Memorizzo l'indirizzo del nome del task in $a0
	li $t6, 0 		# In $t5 Ë memorizato il numero di caratteri stampati
stampaCaratteri:	
	lb $t4,($s0)      	# Carica il primo byte di $s0 in $t4
   	beq $t4,10, esciStampaCaratteri# Se $t4 √® uguale a 10 ( Fine programma ) salto a esciStampaCaratteri
   	beq $t4,3, esciStampaCaratteri # Se $t4 √® uguale a 3 ( Codice per la stampa di un double ) salto a esciStampaCaratteri
   	beq $t4,0, esciStampaCaratteri # Se $t4 √® uguale a 0 ( Terminatore stringa ) salto a esciStampaCaratteri
   	li $v0, 11		# Memorizzo 11 in $v0 ( Stampa di un carattere  )  
   	move $a0,$t4		# Memorizzo $t4 in $a0
   	syscall				
   	addi $t6,$t6,1	# Incremento del numero di task stampati
   	addi $s0,$s0,1	# Incremento di 1 $s0 per passare al byte dopo
   	j stampaCaratteri	# Salto a stampaCaratteri per effettuare un ciclo
esciStampaCaratteri:	# Etichetta per l'uscita dal ciclo
	li $t5,11		# Memorizzo 11 ( Numero degli spazi necessari per mantenere una corretta visualizzazione della tabella)
	sub $t5,$t5,$t6		# Sottraggo agli spazi necessari il numero di caratteri
	move $a0,$t5		# Memorizzo $t5 ( Numero degli spazi necessari ) in $a0 , sar√† usato come argomento della funzione stampaSpazi
	jal stampaNSpazi	# Richiamando stampaNSpazi si stampera' un numero di spazi pari ad $a0

	li $v0,4		# Syscall stampa stringa
	la $a0,stanga		# Caricamento stringa
	syscall				
#Stampa L'esecuzioni rimanenti del Task
	li $a0,10		# Memorizzo in $a0 il numero di spazi necessari per una corretta visualizzazione della tabella con le esecuzioni rimanenti >10
	jal stampaNSpazi	# Salto alla funzuone stampaNSpazi che user√† $a0 come argomento , contiene il numero di spazi da stampare	
	lw $a0,20($t0)		# Memorizzo il numero che indica le esecuzioni rimanenti in $a0
	li $v0,1		# Memorizzo 1 in $v0 per stampare un numero intero
	syscall			# Stampo il numero che indica le esecuzioni rimanenti
	li $t5,11		# Memorizzo in $t5 il numero di spazi necessari per una corretta visualizzazione della tabella
	slti $t4,$a0,10		# Controllo che il numero di esecuzioni rimanenti sia < 10 ,se cos√¨ fosse $t4=1 altrimenti 0
	add $t5,$t5,$t4		# Aggiungo agli spazi necessari il valore $t5 , poich√® per stampare gli spazi necessari dopo un numero ad una cifra ne servir√† uno in pi√π che in quel caso sar√† salvato in $t4 
	move $a0,$t5		# Memorizzo il numero di spazi necessari salvati in $t5 in $a0 , sar√† usato come argomento per la funzione stampaNSpazi
	jal stampaNSpazi	# Salto alla funzione stampaNspazi	
	li $v0,4		# Memorizzo 4 in $a0 per la stampa di una stringa
	la $a0,stangaFineTab	# Memorizzo la stringa da stampare in $a0
	syscall			# Stampa la stringa
	li $v0,4		# Memorizzo 4 in $a0 per la stampa di una stringa
	la $a0,ultimaLienaTab	# Memorizzo la stringa da stampare in $a0
	syscall			# Stampa la stringa 

	lw $t2, 24($t0)		# Caricamento indirizzo successivo in $t2
	beq $t2, $zero, fineStampaTabelle# Se l'indirizzo successivo e' zero l'id non e' stato trovato
			
	lw $t0, 24($t0)		# $t0 prende l'elemento successivo della coda
	j loopStampaRighe 	# Salto all'etichetta per eseguire un altro ciclo

fineStampaTabelle:
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	jr $ra			# Ritorno al chiamante

#Funzione che stampa un numero di spazi pari al valore contenuto in $a0
#Parametro $a0 numero di spazi
stampaNSpazi:
	move $t7,$a0		# Caricamento del numero di spazi in $t7
stampaSpazi:			# Inizio ciclo di stampa spazi
	ble $t7,$zero,fineStampaSpazi	# Si esce dala funzione nel caso in cui non ci sono piu' spazi da stampare
	li $v0,4		# Syscall stampa stringa
	la $a0,spazio		# Caricamento stringa spazi
	syscall
	addi $t7, $t7, -1	# Decremento del numero di spazi rimanenti da stampare
	j stampaSpazi			
fineStampaSpazi:
	jr $ra			# Ritorno al chiamante

# Funzione che conta il numero di caratteri di una stringa
contaLunghezzaNome:
	move $t1,$a0		# Caricamento dell'indirizzo della stringa in $a0
	li $t5,0 		# Counter di quante posizioni si sono scorse
loopSa:				# Ciclo che scorre ogni carattere
	lb $t2,0($t1)		# Caricamento del primo byte della stringa in $t2
	beq $t2,$zero,endString # Se il carattere e' uguale a 0 la stringa e' finita e si esce
increase:
	addi $t1,$t1,1 		# Aumento l'indice di posizione che scorre la stringa
	addi  $t5, $t5, 1      	# Aggiorno il counter delle posizioni gia visitate
	j loopSa
endString: 
	addi $t5,$t5,-1		# Decremento del numero dei caratteri di 1
	move $v0,$t5		# Salvataggio in $v0 del numero di caratteri
	jr $ra			# Ritorno al chiamante

#Errori
errScelta:
      li $v0,4			# Syscall stampa stringa
      la $a0, erroreScelta	# Caricamento stringa
      syscall
      j sceltaMenu 		# Ritorno all'inserimento della scelta

