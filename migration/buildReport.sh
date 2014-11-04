#!/bin/bash

# Windup home
WINDUP_PATH="/home/gustavo/applications/windup-cli-0.6.8/windup-cli-0.6.8"

# Path to tree command. Leave it empty if you already have tree on your path
TREE_PATH=

# Tattletale home
TATTLETALE_PATH="/home/gustavo/applications/tattletale-1.1.2.Final"

# Point this to your apps source folder.
# If you have more than one app, create an folder for each application within SYSTEM_FOLDER
SYSTEM_FOLDER="/home/gustavo/tmp/sistemas"

# Report folder. All reports will be created in this folder.
REPORT_FOLDER="/home/gustavo/tmp/relatorios"

# Folders
WINDUP_FOLDER="$REPORT_FOLDER/windup"
TATTLETALE_FOLDER="$REPORT_FOLDER/tattletale"
TREE_FOLDER="$REPORT_FOLDER/tree"
SINTETICO_FOLDER="$REPORT_FOLDER/sintetico"
ASCII_FOLDER="$REPORT_FOLDER/ascii"

# Are you running windup on application's source?
SOURCE=true

# Java packages from your applications
# Separate them using :
JAVA_PKG="br.gov.dprf:dprf:beans:servlet"

# Do not mess up with the lines below
WINDUP_LOG=windup.log

function check_error {
	if [[ "$?" != 0 ]]; then
		echo -ne "\033[0;31m Error! \033[0m"
		exit 1;
	else
		echo -ne "\033[0;32m Done! \033[0m"
	fi
	echo
}

function exist {
	sup=$(find $1 -name $2)
	if [[ -z $sup  ]] ;then
		echo "No"
	else
		echo -e "\033[0;31m Yes \033[0m"
		printf -- '%s\n' "${sup[@]}"
		echo
	fi
}

function printAscii {
	sup=$(find $1 -name $2)
	if [[ ! -z $sup  ]] ;then
		echo "|$3"
		printf -- '|%s\n' "${sup[@]}"
		echo
	fi
}

# Remove source code from windup. Only leaves xml descriptor.
function clearSource {
	for ext in "*.zip" "*.ear" "*.war" "*.class" "*.java" "*.java.*" "*.jsp" "*.sql" "*.ser" "*.cpp""*.h" "*.c" "*.exe" "*.jar" "*.pdf";
	do
		find $1 -name $ext -exec rm -i {} \;
	done
}

# Parameters
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function windupReport() {
	echo -ne "Gerando relatorio windup..."
	java -jar $WINDUP_PATH/windup-cli.jar -input $1 -source $SOURCE -javaPkgs $JAVA_PKG -fetchRemote true -output $WINDUP_FOLDER/$2  >> $WINDUP_LOG
	check_error
}

# Parameters
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function tattletaleReport() {
	echo -n "Gerando relatorio tattletale..."
	java -jar $TATTLETALE_PATH/tattletale.jar $1 $TATTLETALE_FOLDER/$2
	check_error
}

# Parameters
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function treeSimpleReport() {
	echo -n "Gerando relatorio tree simple..."
	tree -AC $1 > $TREE_FOLDER/$2.tree
	check_error
}

# Parameters
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function treeFullReport() {
	echo -n "Gerando relatorio tree full..."
	tree -ifs $1 > $TREE_FOLDER/$2-fullpath.tree
	check_error
}

function findDescriptorFiles() {

	> $ASCII_FOLDER/$2/descriptor_files.adoc

	# Arquivos descritores
	echo -n "Verificando arquivos descritores..."
	for arq in "Maven#pom.xml" \
	"Ant#build*.xml" \
	"Jasper Report#*.jrxml" \
	"Sun Web Descriptor#sun-web.xml" \
	"EJB Descriptor#ejb-jar.xml" \
	"Log4J#log4j.xml" \
	"Log4J Prop#log4j.properties" \
	"EAP Application#application.xml" \
	"JSF#faces-config*.xml" \
	"Portlet#portlet.xml" \
	"WAR Application#web.xml" \
	"Struts#struts-config.xml" \
	"Bean Validation#validation.xml" \
	"Bean Validation#constraints.xml" \
	"JBoss xml#jboss.xml" \
	"JBoss Web#jboss-web.xml" \
	"JBoss app xml#jboss-app.xml" \
	"Validation Rules#validation-rules.xml" \
	"JBoss Service#jboss-service.xml" \
	"Persistence.xml#persistence.xml" \
	"Mapping JPA#mapping.xml" \
	"JAX-WS#webservices.xml" \
	"CDI#beans.xml" \
	"Services.xml#services.xml" \
	"TLD#*.tld" \
	"Dist#dist.xml" \
	"Sun Application#sun-application.xml" \
	"Permission#permissions.xml" \
	"Web Fragments#web-fragment.xml" \
	"Application Client#application-client.xml" \
	"RA#ra.xml" \
	"weblogic#weblogic.xml" \
	"MANIFEST#MANIFEST.MF" \
	"Sun EJB Descriptor#sun-ejb-jar.xml";
	do	
		tec=$(echo $arq | cut -d"#" -f1)
		arqDesc=$(echo $arq | cut -d"#" -f2)

		echo -n "$tec: " >> $SINTETICO_FOLDER/$2
		exist $1 "$arqDesc" >> $SINTETICO_FOLDER/$2

		printAscii $1 "$arqDesc" $tec >> $ASCII_FOLDER/$2/descriptor_files.adoc
	done
	check_error
}

function countNumberFrameworks() {
	> $ASCII_FOLDER/$2/qtd_components.adoc

	echo -n "Verificando quantidade de frameworks..."
	echo "==> Frameworks" >> $SINTETICO_FOLDER/$2

	OLDIFS=$IFS
	IFS=$'\n'

	for linha in $BUSCA
	do
		result=$(fgrep -R "$linha" $WINDUP_FOLDER/$2/index.html | cut -d"/" -f2 | wc -l)
  	
   		if [ $result != "0" ]; then
   			echo -e "$linha: \033[0;31m$result\033[0m" >> $SINTETICO_FOLDER/$2
   			echo "|$linha" >> $ASCII_FOLDER/$2/qtd_components.adoc
   			echo "|$result" >> $ASCII_FOLDER/$2/qtd_components.adoc
   			echo >> $ASCII_FOLDER/$2/qtd_components.adoc
   		fi
	done

	JSP_QTD=$(cat $WINDUP_FOLDER/$2/index.html | grep jsp.html | cut -d'"' -f2 | wc -l)	
	echo -e "JSPs: \033[0;31m$JSP_QTD\033[0m" >> $SINTETICO_FOLDER/$2
	check_error
	IFS=$OLDIFS
}

function getDependencies() {
	> $ASCII_FOLDER/$2/dependencias.adoc.adoc

	echo -n "Verificando dependencias..."
	echo -e "\n==> Dependencias:" >> $SINTETICO_FOLDER/$2
	for dep in $(cat $TATTLETALE_FOLDER/$2/graphviz/index.html | sed 's/<[^>]*>//g' | sed -r 's/&nbsp;//' | grep .jar | tr -d ' '); do
		echo -e "\033[0;32m $dep \033[0m" >> $SINTETICO_FOLDER/$2
		echo "|$dep" >> $ASCII_FOLDER/$2/dependencias.adoc.adoc
		echo >> $ASCII_FOLDER/$2/dependencias.adoc.adoc
	done
	check_error
}

function getMultiplesJARs() {

	> $ASCII_FOLDER/$2/jars_duplicados.adoc

	echo -n "Verificando JARs duplicados..."
	echo -e "\n==> JARs com classes em comum/duplicados:" >> $SINTETICO_FOLDER/$2
	for mul in $(cat $TATTLETALE_FOLDER/$2/multiplejars/index.html | sed 's/<[^>]*>//g' | sed -r 's/&nbsp;//' | grep .jar | tr -d ' ' | sort | uniq | tr -d ','); do
		echo -e "\033[0;32m $mul \033[0m" >> $SINTETICO_FOLDER/$2
		echo "|$mul" >> $ASCII_FOLDER/$2/jars_duplicados.adoc
		echo >> $ASCII_FOLDER/$2/jars_duplicados.adoc
	done
	check_error
}

function getComponentsLocalization() {
	> $ASCII_FOLDER/$2/components_local.adoc

	echo -n "Verificando qual classe utiliza qual framework..."
	echo -e "\n==> Classe que usam os frameworks:" >> $SINTETICO_FOLDER/$2

	OLDIFS=$IFS
	IFS=$'\n'

	for linha in $BUSCA
	do
		declare -a result=$(cat $WINDUP_FOLDER/$2/index.html | grep -C 2 "Classification: $linha" | grep "a href=" | cut -d'<' -f15 | cut -d'"' -f2 | sed 's/\.html$//g')
		if [[ -n $result ]]; then
   			echo -e "\033[0;32m $linha  \033[0m" >> $SINTETICO_FOLDER/$2
			printf -- '%s\n\n\n\n' "${result[@]}" >> $SINTETICO_FOLDER/$2

			echo "|$linha" >> $ASCII_FOLDER/$2/components_local.adoc
   			printf -- '|%s' "${result[@]}" >> $ASCII_FOLDER/$2/components_local.adoc
   			echo >> $ASCII_FOLDER/$2/components_local.adoc
   		fi
	done

	IFS=$OLDIFS
}

function getJARsUnused() {
	> $ASCII_FOLDER/$2/jars_unused.adoc

	echo -n "Verificando JARs nao utilizados..."
	echo -e "\n==> JARs não utilizados:" >> $SINTETICO_FOLDER/$2
	for mul in $(cat $TATTLETALE_FOLDER/$2/unusedjar/index.html | sed 's/<[^>]*>//g' | sed -r 's/&nbsp;//' | tr -d ' ' | grep -B1 No | tr -d '-' | grep -v No | sed '/^$/d'); do
		echo -e "\033[0;32m $mul \033[0m" >> $SINTETICO_FOLDER/$2
		echo "|$mul" >> $ASCII_FOLDER/$2/jars_unused.adoc
		echo >> $ASCII_FOLDER/$2/jars_unused.adoc
	done
	check_error
}

function getJSPs() {
	> $ASCII_FOLDER/$2/components_local.adoc

	declare -a resultJSP=$(cat $WINDUP_FOLDER/$2/index.html | grep jsp.html | cut -d'"' -f2 | sed 's/\.html$//g')
	echo -e "\033[0;32m JSPs  \033[0m" >> $SINTETICO_FOLDER/$2	
	printf -- '%s\n' "${resultJSP[@]}" >> $SINTETICO_FOLDER/$2

	echo "|JSPs" >> $ASCII_FOLDER/$2/components_local.adoc
   	printf -- '|%s' "${resultJSP[@]}" >> $ASCII_FOLDER/$2/components_local.adoc
   	echo >> $ASCII_FOLDER/$2/components_local.adoc

	check_error
}

function getJARsFromJBoss() {
	> $ASCII_FOLDER/$2/dependencias_sa.adoc

	echo -e "\n==> JARs já fornecidos pelo JBoss:" >> $SINTETICO_FOLDER/$2
	echo -n "Verificando JARs já fornecidos pelo JBoss..."
	
	# OLDIFS=$IFS

	# IFS=$'\n'

	# arrayJars

	# jars=$(curl -s https://access.redhat.com/articles/1122333 | sed -e 's/&/&amp;/g' | xmlstarlet sel -t -m "//*[@id=\"article-content\"]/table//td//." -v "text()" -o "#" -n | sed -e '/^#$/d' | awk '/[a-z0-9]#$/ { printf("%s", $0); next } 1' | sed 's/#$//g' )
	# for jar in $jars 
	# do
	# 	pkg=$(echo $jar | cut -d "#" -f1)
	# 	status=$(echo $jar | cut -d "#" -f2)

	# 	sizePkg=$(tr -dc '.' <<<"$jar" | awk '{ print length; }')

	# 	if [ "$sizePkg" = "1" ] ;then
	# 		arrayJars="$arrayJars $(echo pkg | cut -d '.' -f2)"
	# 	elif [  ] ;then

	# 	fi

	# 	echo $size
	# done

	# IFS=$OLDIFS

	# read

	for jar in "asm" "cal10n" "guava" "h2" "activation" "jsf-api" "hibernate-jpa" "connector-api" "el-api" "validation-api" "jaxrs-api" "ejb-api" "annotations-api" "jacc-api" "jaspi-api" "javax.inject" "mail" "jsr181-api" "transaction-api" "jaxb-api" "saaj-api" "jaxws-api" "jaxrpc-api" "jaxr-api" "rmi-api" "wsdl4j" "jstl-api" "servlet-api" "jsp-api" "interceptors-api" "cdi-api" "jad-api" "jms-api" "xom" "codemodel" "jsf-impl" "jaxb-xjc" "jaxb-impl" "saaj-impl" "txw2" "istack-commons" "xsom" "relaxngDatatype" "jcip-annotations" "infinispan-core" "infinispan-client-hotrod" "infinispan-cachestore-jdbc" "infinispan-cachestore-remote" "opensaml" "xmltooling" "openws" "snakeyaml" "javassist" "jgroups" "jackson" "jettison" "woodstox" "stax2" "org.osgi" "jaxen" "hibernate-entitymanager" "hibernate-core" "hibernate-infinispan" "hibernate-commons-annotations" "hibernate-envers" "hibernate-validator" "hornetq" "jacorb" "jansi" "picketlink" "antlr" "aesh" "marshalling" "metadata" "netty" "xnio" "slf4j" "jaxb" "cxf" "staxmapper" "jms" "ironjacamar" "httpserver" "resteasy" "jaxr" "mod_cluster" "jpa" "shrinkwrap" "common-beans" "weld" "joda" "apache-mime4j" "wss4j" "httpclient" "httpmime" "httpcore" "xerces" "commons-io" "commons-cli" "commons-pool" "commons-codec" "commons-lang" "commons-beanutils" "commons-configuration" "commons-collections" "xalan" "xts" "uddi" "velocity" "neethi" "dom4j" "picketbox" "rngom" "scannotation" "slf4j" "jdom" "asm" "hibernate-search" "richfaces" "seam" "snowdrop" "struts" "arquillian" "gwt" "spring" "icefaces" "grails";
	do
		resp=$(grep -e ".*$jar.*jar$" $TREE_FOLDER/$2-fullpath.tree | cut -d"]" -f2 | tr -d ' ')
		if [ "x$resp" != "x" ] ;then

			echo "$resp" >> $SINTETICO_FOLDER/$2
			echo "$resp" | awk {'print "|"$1'} >> $ASCII_FOLDER/$2/dependencias_sa.adoc
		fi
	done
	check_error
}

# Parameters
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function sinteticoReport() {
	mkdir -p $SINTETICO_FOLDER
	
	echo -e "############################ \033[0;31m $2 \033[0m ############################\n" > $SINTETICO_FOLDER/$2
	
	# Find descriptor files
	findDescriptorFiles $1 $2

	# Count frameworks
	countNumberFrameworks $1 $2

	# Component localization
	getComponentsLocalization $1 $2

	# JSP
	getJSPs $1 $2

	# Get dependency
	getDependencies $1 $2

	# Get JARS duplicated
	getMultiplesJARs $1 $2

	# Get JARs unused
	getJARsUnused $1 $2

	getJARsFromJBoss $1 $2

}

function findRules() {

	PACOTE_FILE_EXTENSION=$(fgrep -R "import " $SYSTEM_FOLDER | grep -v "@import" | grep -v "<import" |  grep -v "import javax" | grep -v "import $1" | grep -v "import java." | cut -d":" -f 2 | uniq | sort | sed '/^import/!d' | cut -d" " -f2 | awk -F. '{
	if(match(substr($2,0,1),"[A-Z]"))
	print "<windup:java-classification source-type=\042"$1"\042 description=\042"$1"\042 effort=\0420\042/>"
	else if(match(substr($3,0,1),"[A-Z]"))
	print "<windup:java-classification source-type=\042"$1"."$2"\042 description=\042"$1"."$2"\042 effort=\0420\042/>"
	else if (match(substr($4,0,1),"[A-Z]"))
	print "<windup:java-classification source-type=\042"$1"."$2"."$3"\042 description=\042"$1"."$2"."$3"\042 effort=\0420\042/>"
	else
	print "<windup:java-classification source-type=\042"$1"."$2"."$3"\042 description=\042"$1"."$2"."$3"\042 effort=\0420\042/>"
	fi
	}' | uniq)
	
	PACOTE_FILE_CONTEXT=$(fgrep -R "import " $SYSTEM_FOLDER | grep -v "@import" | grep -v "<import" |  grep -v "import javax" | grep -v "import $1" | grep -v "import java." | cut -d":" -f 2 | uniq | sort | sed '/^import/!d' | cut -d" " -f2 | awk -F. '{
	if(match(substr($2,0,1),"[A-Z]"))
	print "<value>"$1"</value>"
	else if(match(substr($3,0,1),"[A-Z]"))
	print "<value>"$1"."$2"</value>"
	else if (match(substr($4,0,1),"[A-Z]"))
	print "<value>"$1"."$2"."$3"</value>"
	else
	print "<value>"$1"."$2"."$3"</value>"
	fi
	}' | uniq)
}
	
function newRules() {

	OLDIFS=$IFS
	IFS=$'\n'

	if [ "x$1" = "x" ] ;then
		# Gerando arquivos de novas regras
		echo -n "Verificando pacotes ainda não existentes no windup..."
		findRules $JAVA_PKG
		check_error

		echo "################################################################################################"
		echo "#### Pare tudo! Abra o arquivo extension-example.windup.xml e crie as novas regras do windup ###"
		echo "################################################################################################"
		echo "Enter para prosseguir"
		read lixo

		for pac in $PACOTE_FILE_EXTENSION
		do
			echo "$pac" 
		done

		echo "############################################################################################"
		echo "#### Pare tudo! Abra o arquivo jboss-windup-context.xml e crie as novas regras do windup ###"
		echo "############################################################################################"
		echo "Enter para prosseguir"
		read lixo

		for pac in $PACOTE_FILE_CONTEXT
		do
			echo "$pac" 
		done

	else
		# Gerando arquivos de novas regras
		echo -n "Verificando pacotes ainda não existentes no windup..."
		#fgrep -R "import " $SYSTEM_FOLDER/$1 | grep -v "@import" | grep -v "<import" |  grep -v "import javax" | grep -v "import $JAVA_PKG" | grep -v "import java." | cut -d":" -f 2 | sort | uniq | less > $PACOTE_FILE
		findRules $JAVA_PKG
		check_error

		echo "###############################################################################"
		echo "#### Pare tudo! Abra o arquivo pacotes.txt e crie as novas regras do windup ####"
		echo "###############################################################################"
		echo "Enter para prosseguir"
		read lixo
	fi

	IFS=$OLDIFS
}

function createBusca() {
	echo -n "Loading busca"
	BUSCA=$(cat $WINDUP_PATH/rules/extensions/extension-example.windup.xml | grep 'java-classification source-type="IMPORT"' | cut -d'=' -f4 | cut -d'"' -f2)
	BUSCA=$(echo -e "$BUSCA\nEJB 1.x/2.x - Home Interface")
	BUSCA=$(echo -e "$BUSCA\nEJB 1.x/2.x - Remote Interface")
	BUSCA=$(echo -e "$BUSCA\nEJB 1.x/2.x - Entity Bean")
	BUSCA=$(echo -e "$BUSCA\nEJB 1.x/2.x - Session Bean")
	BUSCA=$(echo -e "$BUSCA\nEJB 2.x - Local Home")
	BUSCA=$(echo -e "$BUSCA\nEJB 2.x - Local Object")
	BUSCA=$(echo -e "$BUSCA\nEJB 2.x - Message Driven Bean")
	BUSCA=$(echo -e "$BUSCA\nEJB 3.x - Message Driven Bean")
	BUSCA=$(echo -e "$BUSCA\nEJB 3.x - Local Session Bean Interface")
	BUSCA=$(echo -e "$BUSCA\nEJB 3.x - Remote Session Bean Interface")
	BUSCA=$(echo -e "$BUSCA\nEJB 3.x - Stateless Session Bean")
	BUSCA=$(echo -e "$BUSCA\nEJB 3.x - Stateful Session Bean")
	BUSCA=$(echo -e "$BUSCA\nHibernate Mapping")
	BUSCA=$(echo -e "$BUSCA\nHibernate 2.0 Mapping")
	BUSCA=$(echo -e "$BUSCA\nJSP Tag Library")
	BUSCA=$(echo -e "$BUSCA\nCommons Validator Rules Configuration")
	BUSCA=$(echo -e "$BUSCA\nHibernate Configuration")
	BUSCA=$(echo -e "$BUSCA\nOracle Application Platform Web Descriptor")
	BUSCA=$(echo -e "$BUSCA\nJasperReports Report Design")
	BUSCA=$(echo -e "$BUSCA\nWAR Application Descriptor")
	BUSCA=$(echo -e "$BUSCA\nArchiveMeta Manifest")
	#BUSCA="$BUSCA"".jsp"
	BUSCA=$(echo -e "$BUSCA\n.xhtml")

	check_error
}

function limpaFonte() {

	if [ "x$1" = "x" ] ;then
		# Limpa fontes de arquivos invalidos e vazios
		echo -n "Limpando fontes (arquivos vazios e com pacote default)..."
		find $SYSTEM_FOLDER -name *.java -type f -empty -exec rm -i {} \;
		for filerm in $(find $SYSTEM_FOLDER -name *.java -exec grep -L package {} \;)
		do
			rm -i $filerm
		done
		check_error
	else
		# Limpa fontes de arquivos invalidos e vazios
		echo -n "Limpando fontes (arquivos vazios e com pacote default)..."
		find $SYSTEM_FOLDER/$1 -name *.java -type f -empty -exec rm -i {} \;
		for filerm in $(find $SYSTEM_FOLDER/$1 -name *.java -exec grep -L package {} \;)
		do
			rm -i $filerm
		done
		check_error
	fi


}

#########################################################################################################
#########################################################################################################
#########################################################################################################
#########################################################################################################
#########################################################################################################

# Creating report folder
mkdir -p $WINDUP_FOLDER
mkdir -p $TATTLETALE_FOLDER
mkdir -p $TREE_FOLDER
mkdir -p $SINTETICO_FOLDER
mkdir -p $ASCII_FOLDER

if [ "$#" = 0 ] ;then

	# Creating new rules
	newRules

	# Busca.txt
	createBusca

	# Limpa os fontes
	limpaFonte

	if [ $SOURCE == true ]; then
		# Gera relatorio

		for sistema_path in $(find $SYSTEM_FOLDER -maxdepth 1 -type d | sed -e "1d")
		do
			#sistema=$(echo $sistema_path | cut -d'/' -f6)

			sistema=$(echo $sistema_path | awk -F/ '{ print $NF }')
			
			mkdir $ASCII_FOLDER/$sistema 2>/dev/null

			echo -e "\n\n### $sistema ###"

			windupReport $sistema_path $sistema

			tattletaleReport $sistema_path $sistema
	
			treeSimpleReport $sistema_path $sistema

			treeFullReport $sistema_path $sistema

			sinteticoReport $sistema_path $sistema
	
		done
	else
		for sistema_path in $(ls -d $SYSTEM_FOLDER/*)
		do
			sistema=$(echo $sistema_path | awk -F/ '{ print $NF }')
		
			echo $sistema_path
			
			echo -e "\n\n### $sistema ###"

			windupReport $sistema_path $sistema

			tattletaleReport $sistema_path $sistema
	
			treeSimpleReport $sistema_path $sistema

			treeFullReport $sistema_path $sistema

			sinteticoReport $sistema_path $sistema
	
		done
	
		
	fi
	
	

	# Limpa dados
	#echo "Limpando fontes..."
	#clearSource $WINDUP_FOLDER
	#check_error

	#limpa arquivos tmp
	rm $WINDUP_LOG

	# zipa relatório
	#tar -jcvf relatorio.tar.bz2 $WINDUP_FOLDER



elif [ "$#" = 1 ] ;then
	
	# Creating new rules
	newRules $1

	# Busca.txt
	createBusca

	# Limpa os fontes
	limpaFonte $1

	# Gera relatorio
	#for sistema_path in $(find $SYSTEM_FOLDER -maxdepth 1 -type d | sed -e "1d")
	#do
		#sistema=$(echo $sistema_path | cut -d'/' -f6)
	
	sistema_path=$SYSTEM_FOLDER/$1

	echo -e "\n\n### $1 ###"

	windupReport $sistema_path $1

	tattletaleReport $sistema_path $1
	
	treeSimpleReport $sistema_path $1

	treeFullReport $sistema_path $1

	sinteticoReport $sistema_path $1
	
	#done

	# Limpa dados
	#clearSource $WINDUP_FOLDER

	#limpa arquivos tmp
	rm $WINDUP_LOG

	# zipa relatório
	#tar -jcvf relatorio.tar.bz2 $WINDUP_FOLDER



fi





