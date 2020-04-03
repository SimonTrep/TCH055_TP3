--======================================
--===========Question 1=================
-- Fonction: Permet ou empêche l’inscription à un nouveau cours d’un étudiant
-- Description:
--  Le trigger vérifie s’il est permis à l’étudiant de s’inscrire 
--  à un nouveau cours ou pas
-- Écris par: Nadir Grib
--=======================================
create or replace TRIGGER TRG_verifier_note_etudiant 
-- Avant insertion
BEFORE INSERT ON Inscription FOR EACH ROW 
-- Déclaration de 2 variables, dont une est le seuil de comparaison
DECLARE seuil NUMBER:= 50;
        notemin NUMBER;
BEGIN
-- Sélection de la note la plus petite parmi les cours de l’étudiant (retrouvé grâce au code permanent)
    SELECT MIN(note) INTO notemin FROM Inscription i WHERE i.codepermanent = :NEW.codepermanent;
-- Évaluation de la note par rapport au SEUIL
    IF (notemin) <= seuil THEN
-- L’inscription est empêché grace au ‘’RAISE_APPLICATION_ERROR’’
    RAISE_APPLICATION_ERROR(-20001, 'Vous ne pouvez pas vous inscrir parce que vous avez une note inférieur ou égal à 50.');

    ELSE
    DBMS_OUTPUT.PUT_LINE('Vous avez été inscrit avec succès.');

    END IF;
END TRG_verifier_note_etudiant;
/


--======================================
--===========Question 2=================
--Fonction: f_verifier_statut_etudiant
--Description:
--Vérification du statut de l'Étudiant. la fonction recoit en argument le code permanent et le code de session et renvoie 
--une chaine de caractère 'Temps pleins' si l'étudiant est inscrit a plus de 12 crédit sinon elle renvoie 'Temps partiel' 
--Écris par: Simon Trépanier
--=======================================

--La fonction est créée ou remplacée ici
CREATE OR REPLACE FUNCTION f_verifier_statut_etudiant(f_codePermanent inscription.codepermanent%TYPE, f_codeSession inscription.codesession%TYPE)

RETURN VARCHAR IS
        Statut VARCHAR(20):= NULL;
--création d'un variable de type number pour storer le nombre de crédit toal de l'étudiant
totalcredit number;

--début de la fonction
BEGIN

--Sélection du total de crédit
    SELECT SUM(nbcredits)
    INTO totalcredit
    FROM cours
    WHERE sigle IN
--sélection de l'étudiant et de la session
                  (SELECT sigle 
                   FROM inscription 
                   WHERE codepermanent=f_codePermanent 
                   AND codesession=f_codeSession) ;    
--Condition de choix selon le nombre de crédit                  
    IF totalcredit> 12
    THEN Statut:='Temps Plein';  
    
    ELSE
    Statut:='Temps Partiel';
    END IF;       
--retourne le statut de l'étudiant    
RETURN Statut;

END;
/
--Exécution de la fonction de la question 2 avec un code permanent et un code de session
exec DBMS_OUTPUT.PUT_LINE(f_verifier_staut_etudiant('TREL14027801','32003'));
/
--======================================
--===========Question 3=================
--Fonction: f_actif
--Description:
--Fonction qui recçoit en argument le codepermanent d'un étudiant et indique son statut comme étant actif si il
--suit au moins un cours dans la session courante ou bien non actif si les conditions précédentes ne sont pas respecté
--Écris par: Herby Régis
--Modifications par: Simon Trépanier
--=======================================

CREATE OR REPLACE FUNCTION f_actif (f_codepermanent  inscription.codepermanent%type) /* La fonction f_actif est créé ici*/
RETURN VARCHAR2 IS

actif varchar2(10):=NULL;
totalcours number;

BEGIN
     SELECT COUNT(sigle)  /* Ici se produit la sélection des paramètre à évaluer */
     INTO totalcours
     FROM inscription
     WHERE f_codepermanent = codepermanent AND 
           codesession = (SELECT codesession --le script compte le nombre de sigle auxquelles l'étudiant est inscrit pour valider que l'étudiant est au moins
                          FROM sessionets  --inscrit a 1 cours et évalue la date actuelle pour voir si elle est inclue entre la date de début d'une session et la finde celle-ci
                          WHERE sysdate BETWEEN datedebut AND datefin );  
     
     IF totalcours >= 1  THEN  /* Ici est instancié l'évalution conditionnel de la fonction pour indiquer le statut de l'étudiant*/
     actif:='Actif';
     ELSE
     actif:='Innactif'; 
     END IF;
     
    RETURN actif;
    
END f_actif;  /* Fin de la fonction*/
/

--Execution de la fonction de la question3. Tester avec un code permanent. La focntion renvoie toujours Innactif car il n'y a aucun session active dans la BD
exec DBMS_OUTPUT.PUT_LINE(f_actif('TREL14027801'));
/
--======================================
--===========Question 4=================
--Fonction:L CODEPROFESSEUR_GAN
--Création d’une fonction PL/SQL pour générer les codes des Professeurs (codeProfesseur)
--Ceci prend en argument le prenom et nom d'unprofesseur et retourne son code a lui formé de 3 lettres suivies 
--(Trois premières lettres du nom de famille en majuscule, suivit de la première lettre du prénom en majuscule et d’un chiffre en utilisant un compteur
--Écris par: Glen Pham
--Modifications par: Simon Trépanier
--=======================================

create or replace FUNCTION CODEPROFESSEUR_GAN(prenomProf Professeur.prenom%TYPE, nomProf Professeur.nom%TYPE)
    RETURN Professeur.codeprofesseur%TYPE IS 
        codeProf Professeur.codeprofesseur%TYPE;    /* Retourne un valeur nommer de meme type que de l'attribut codeProfessuer */
        totalCode number;
    BEGIN
       
        SELECT count(codeprofesseur)   /* Compte le nombre de code professeur ayant les memes 4 lettres */
        INTO totalCode
        FROM Professeur
        WHERE UPPER(CONCAT(SUBSTR(prenomProf,0,3),SUBSTR(nomProf,0,1))) = SUBSTR(codeprofesseur,0,4);    /* Choisi le code du professuer approprier ou les conditions sont remplis */
        
        --Création du code professeur a aprtir des 4 lettres et d'un chiffre
        codeprof:=UPPER(CONCAT(SUBSTR(nomProf,0,3),CONCAT(SUBSTR(prenomProf,0,1),totalCode+1)));

        RETURN codeProf;
        
    END CODEPROFESSEUR_GAN;
/
--Exécution de la fonction de la question 4 avec le professeur déja existant Pascal Blaise
exec DBMS_OUTPUT.PUT_LINE(CODEPROFESSEUR_GAN('jean' ,'tremblay' ));
/
--======================================
--===========Question 5=================
--Fonction: f_CotePourNote
--Description:
--Altération de la table inscription afin d'ajouter une colonne avec les cotes A B C D E
--Création d'une fonction pour assigner une Cote selon la note d'un étudiant.  
--Écris par: Simon Trépanier
--=======================================

--Création de la nouvelle colonne pour les cotes A B C D E 
ALTER TABLE INSCRIPTION
ADD Cote CHAR(1)
CONSTRAINT CHK_Cote CHECK(Cote IN(NULL,'A','B','C','D','E'));
/
--Création de la fonction qui recoit un nombre en argument et renvoit une Cote
CREATE OR REPLACE FUNCTION f_CotePourNote(note number)

RETURN CHAR IS
        Cote CHAR(1):= NULL;

BEGIN
--Début des condtions pour choisir la cote approprié
    IF note <= 59
    THEN Cote := 'E';  
    
    ELSIF  note BETWEEN 59 AND  69
    THEN Cote := 'D';   
    
    ELSIF note BETWEEN 70 AND 79
    THEN Cote := 'C';   
    
    ELSIF  note BETWEEN 80 AND  89
    THEN Cote := 'B';   
    
    ELSE
    Cote := 'A';
    
    END IF;       
 --Renvoit de la cote   
RETURN Cote;

END;
/
--Mise a jour de la cote pour chaque élève
UPDATE inscription
SET cote=f_CotePourNote(note)
WHERE note IS NOT null;
/
--affichage du tableau
select *
from inscription;
/

--======================================
--===========Question 6=================
--Procédure: pBulletin
--Description:
--Création d'une procédure qui affiche le buleltin d'un étudiant
--La précdure recoit en argument le code permanent d'un étudiant et affiche 
--chaque cours suivis ainsi que la note et la cote associée.
--Écris par: Simon Trépanier
--=======================================

--Création de la procédure qui recoit en argument le code permanent d'un étudiant
CREATE OR REPLACE PROCEDURE pBulletin (p_codePermanent IN etudiant.codepermanent%type)
AS
--création de variables pour storer les informations sur l'étudiant
p_nom  etudiant.nom%type;
p_prenom etudiant.prenom%type;

--création d'un curseur qui permettera de aprcourir la table inscription ligne par ligne
CURSOR cur_bulletin IS
SELECT sigle,nogroupe,codesession,note,cote
FROM inscription
WHERE inscription.codepermanent = p_codepermanent;

BEGIN

--sélection du nom et prénom de l'étudiant
SELECT nom,prenom INTO p_nom,p_prenom FROM etudiant WHERE etudiant.codepermanent = p_codePermanent;

--affichage de la premièere partie du bulletin
dbms_output.put_line ('Code Permanent :'|| p_codePermanent );
dbms_output.put_line ('Nom :'|| p_nom  );
dbms_output.put_line ('Prenom :'|| p_prenom  );
dbms_output.put_line ('Sigle' ||  '      ' || 'noGroupe' || '    ' || 'Session' || '    ' || 'Note' || '   ' || 'Cote');

--Boucle FOR qui servira à afficher les notes de l'étudiant a l'aide du curseur
FOR i IN cur_bulletin
LOOP
dbms_output.put_line( i.sigle || '    ' || i.nogroupe || '          ' || i.codesession || '      ' || i.note || '     ' || i.cote);
END LOOP;
 
END;
/
--exécution de la procédure de la question 6 
EXEC pBulletin('TREJ18088001') 
/
--======================================
--===========Question 7=================
--Fonction:  f_anciennete_prof
--Description:
--Fonction indiquera  si un enseignant a déjà enseigné un cours en particulier. Elle prend le sigle du cours et le code du professeur en parametres 
--etretour 0 pour non et 1 pour oui. La requete ci-desosus compte le # de fois qu'un prof a enseigner un cours specifique. Si le compte est plus grand
--que 0, alors sa veut dire qu'il a enseigner le cours
--Écris par: Glen Pham
--=======================================

create or replace FUNCTION f_anciennete_prof(matricule GroupeCours.codeprofesseur%TYPE, sigle_x GroupeCours.sigle%TYPE)
    RETURN  NUMBER IS  indice CHAR(3);
    nb_occurence NUMBER(1);
    BEGIN
    
        SELECT COUNT(*)     /* La requete compte le nombre de fois ou le professeur specifier a enseigner le sigle/cours qu'on veut savoir */
        INTO nb_occurence
        FROM GroupeCours
        WHERE sigle = sigle_x AND codeProfesseur = matricule;   /* Compte dependant de la condtion que les deux arguments se trouvent dans la meme ligne du tableau GroupeCours */
        
        IF nb_occurence >0 THEN
            indice := '1';                          /* Si le prof a enseigner au moin une fois alors on retourne 1 = Oui */
        ELSIF nb_occurence = 0 THEN
            indice := '0';                      /* Si le prof n'a pas enseigner le cour specifique  alors on retourne 0 = Non */
        END IF;
        
        RETURN indice;
    END;
/
--Exécution de la fonction de la question 7 avec le matricule du professeur et le sigle d'un cours
exec DBMS_OUTPUT.PUT_LINE(f_anciennete_prof('PASB1' ,'INF3123' ));
/
--======================================
--===========Question 8=================
--Trigger: nouvelleCote
--Description:
--Trigger qui fait une mise à jour de la cote d'un étudiant si celui-ci à une note qui est modifié dans son dossier
--Écris par: Herby Régis
--Modifié par: Simon Trépanier
--=======================================
CREATE OR REPLACE TRIGGER nouvelleCote   /* Ici on initialise le trigger nouvelleCote*/
AFTER UPDATE ON inscription
FOR EACH ROW
DECLARE                                               
    TABLE_MUTANTE EXCEPTION;                    -- À cette endroit est déclaré une instance considérant les tables mutante généré par
    PRAGMA EXCEPTION_INIT(TABLE_MUTANTE,-4091); --la fonction f_cotepournote 

BEGIN
    /* Ici est fait l'évaluation de l'état de la note si elle a été modifié ou non pour ensuite appeler la fonction  f_cotepournote
    et l'instancier avec la nouvelle note mise à jour dans le bu d'avoir une nouvelle cote*/
     
     UPDATE inscription
     SET cote=f_CotePourNote(:NEW.note)
     WHERE sigle = :OLD.sigle AND noGroupe = :OLD.noGroupe AND codeSession = :OLD.codeSession AND codepermanent = :OLD.codepermanent;
     
     

EXCEPTION
        WHEN TABLE_MUTANTE THEN       /* À cette endroit est déclaré une instance considérant les tables mutante généré par la fonction f_cotepournote */
        DBMS_OUTPUT.PUT_LINE('Alerte');
END;
/
--Test de mise a jour de la note et la cote pour la question 8
update inscription
set note = 80
where sigle='INF5180' and codepermanent ='DEGE10027801' and nogroupe='10' and codesession= '12004';
rollback;
/
--======================================
--===========Question 9=================
-- Fonction: Création d’une vue sur le sigle, le noGroupe, codeSession 
-- et la moyenne du groupe correspandant
-- Description:
--  La création de la vue permet de voir la moyenne d’un groupe
--  selon le sigle, le noGroupe et le codeSession
-- Écris par: Nadir Grib
--=======================================
CREATE OR REPLACE VIEW MOYENNEPARGROUPE AS
SELECT sigle, noGroupe, codeSession, avg(note) AS "MOYENNEGROUPE"
FROM Inscription
-- On regroupe les notes selon le noGroupe, le sigle et le codesession
GROUP BY noGroupe, sigle, codesession
/
--======================================
--===========Question 9=================
-- Fonction: Mise à jour des notes d'un groupe
-- Description:
--  Met à jour les notes d'un groupe à la place de la moyenne du groupe
-- Écris par: Nadir Grib
--=======================================
create or replace TRIGGER InsteadUpdateMoyenneParGroupe
-- Empêche la mise à jour qui à déclenché le "Trigger"
INSTEAD OF UPDATE
ON MoyenneParGroupe
FOR EACH ROW

BEGIN
-- Met à jour les notes du groupe visé, ce qui change automatiquement la moyenne du groupe
    UPDATE Inscription SET note = note + (:NEW.moyenneGroupe - :OLD.moyenneGroupe)
    WHERE sigle = :OLD.sigle AND noGroupe = :OLD.noGroupe AND codeSession = :OLD.codeSession AND note IS NOT NULL;
-- Un message pour valider que le trigger à bien fonctionné
    DBMS_OUTPUT.put_line('Les notes ont été mise à jour.');
END InsteadUpdateMoyenneParGroupe;

/
--Essais d'update pour la question 9
 UPDATE MoyenneParGroupe
 SET moyenneGROUPE = 70   
 WHERE sigle = 'INF1130'AND noGroupe = 10 AND codeSession = 32003   
 / 
 --Affichage de la vue pour la question 9
 SELECT * 
 FROM MoyenneParGroupe 
 WHERE sigle = 'INF1130'AND noGroupe = 10 AND codeSession = 32003 
/
--affichage des notes pour la question 9 
SELECT * 
FROM Inscription   
WHERE sigle = 'INF1130'AND noGroupe = 10 AND codeSession = 32003 
/


