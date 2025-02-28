# snowflake_bielik_llm

Do instalacji modelu będziesz potrzebować systemu operacyjnego (proponujemy Ubuntu) z następującymi narzędziami:
* git
* Docker (<https://www.docker.com>)
* Snow CLI (<https://sfc-repo.snowflakecomputing.com/snowflake-cli/index.html>)

Dodatkowo niezbędny będzie token dla Twojego konta w HuggingFace (patrz <https://huggingface.co/docs/hub/security-tokens>).

Po zainstalowaniu powyższych pierwszy krok stanowi konfiguracja połączenia do Snowflake:
```
snow connection add --connection-name <Nazwa połączenia Snow> --account <Snowflake Account Identifier> --user <Użytkownik Snowflake> --password <Hasło>
```

__UWAGA__ Użytkownik musi mieć uprawnienie Account Admin

W kolejnym kroku wykonaj klon niniejszego repozytorium i przejście do utworzonego katalogu:
```
git clone https://github.com/frodo2000/snowflake_bielik_llm.git
cd snowflake_bielik_llm
```

Teraz pozostaje uruchomienie skryptu instalacyjnego. Możesz to zrobić w trybie interaktywnym:
```
./setup_projects.sh
```
Wówczas skrypt poprosi Cię kolejno o:
- HuggingFace token
- Snowflake Account Identifier (ten sam który został użyty dla tworzonego połączenia)
- Snowflake Database - nazwa bazy, w której znajdzie się model
- Snow Connection Name - nazwa połączenia w snow, które zostało stworzone powyżej

Alternatywnie możesz podać wszystkie parametry podczas wywołania skryptu:
```
./setup_project.sh -hf_token <HuggingFace token> -snowflake_account <Snowflake Account Identifier> -snowflake_database <Snowflake Database> -snow_connection_name <Snow Connection Name>
```

Wywołanie skryptu obejmuje dwie fazy:
- Przygotowanie, w którym pliki z rozszerzeniem org (w katalogach Bielik_Service i Bielik_Setup_Scripts) zostaną skopiowane i zdefiniowane w nich znaczniki zmiennych (otoczone znakami <>  jak na przykładowych wywołaniach) zostaną zamienione wartościami zdefiniowanymi przez Ciebie. Po tej fazie zostaniesz zapytany czy chcesz kontynuować. Będziesz mieć czas by zobaczyć czy wprowadzono wszystkie zmienne poprawnie i czy znajdują się one w przygotowanych skryptach.
- Przygotowanie, w którym pliki z rozszerzeniem org (w katalogach Bielik_Service i Bielik_Setup_Scripts) zostaną skopiowane i zdefiniowane w nich znaczniki zmiennych (otoczone znakami mniejszo jak na przykładowych wywołaniach) zostaną zamienione wartościami zdefiniowanymi przez Ciebie. Po tej fazie zostaniesz zapytany czy chcesz kontynuować. Będziesz mieć czas by zobaczyć czy wprowadzono wszystkie zmienne poprawnie i czy znajdują się one w przygotowanych skryptach.
- Uruchomienie wdrożenia. W tej fazie wykonane zostaną:
	- utworzenie bazy danych
	- utworzenie roli administracyjnej dla tej bazy
	- nadanie niezbędnych uprawnień do roli oraz przypisanie użytkownika zdefiniowanego w połączeniu do roli
	- utworzenie repozytorium kontenerów
	- utworzenie obiektów Stage
	- utworzenie reguł sieciowych oraz integracji
	- utworzenie puli wykonawczej
	- zbudowanie i wysłanie do Snowflake obrazów Docker
	- utworzenie usługi i zarejestrowanie niezbędnych funkcji użytkownika
__UWAGA__ W trakcie procesu - jeżeli masz zdefiniowane MFA będziesz proszony o potwierdzanie tożsamości kilkukrotnie (np przez alerty aplikacji DUO).

Po wdrożeniu musisz uzbroić się w cierpliwość. Przy pierwszym uruchomieniu usługi będzie pobierany model Bielik. Trwa to chwilę. Aby sprawdzić czy Bielik jest już gotowy do pracy wpisz w konsoli Snowflake:
```
SELECT RIGHT(SYSTEM$GET_SERVICE_LOGS( 'BIELIK', 0, 'bielik-vllm'),23);
```
Zwrócona wartość powinna być następująca:
```
vLLM server is ready.
```

Teraz możesz już zacząć korzystać z Bielika. Masz do dyspozycji dwie funkcje:
```
bielik_complete(user_prompt varchar)
```
oraz
```
bielik_complete(prompt array, options object)
```
obydwie odpowiadają funkcjom CORTEX.COMPLETE (są jedynie pozbawione zmiennej z nazwą modelu).

Korzystając z dokumentacji https://docs.snowflake.com/en/sql-reference/functions/complete-snowflake-cortex powineneś poczuć się z bielik_complete jak w domu. Zarówno parametry jak i zwracane struktury są analogiczne.
To co różni się w stosunku do dokumentacji Snowflake:
- wartość domyślna parametru temperature to 1 (wartość 0 jest spoza zakresu, więc użyto wartości domyślnej z OpenAI)
- wartość domyślna parametru top_p to 1 (wartość 0 jest spoza zakresu, więc użyto wartości domyślnej z OpenAI)
- nie jest obsługiwany parametr guardrails

Źródła inspiracji:
- https://medium.com/@daniel.ong_3518/deploy-any-llm-on-spcs-with-vllm-7442f00d02d5
- https://github.com/Snowflake-Labs/snowpark-containers-llama-2-sample/blob/main/README.md#llama-2-and-snowpark-container-services-demo