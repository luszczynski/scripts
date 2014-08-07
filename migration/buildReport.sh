#!/bin/bash

WINDUP_PATH="/home/admin1/redhat/software/windup/windup-cli-0.6.8"
TREE_PATH="/home/admin1/redhat/software/tree"
TATTLETALE_PATH="/home/admin1/redhat/software/tattletale/tattletale-1.1.2.Final"

SISTEMAS_PATH="/home/admin1/redhat/sistemas"

WINDUP_REPORT="/home/admin1/redhat/relatorios/windup/reportWindup"
TATTLETALE_REPORT="/home/admin1/redhat/relatorios/tattletale/reportTattletale"
TREE_REPORT="/home/admin1/redhat/relatorios/tree/reportTree"
SINTETICO_REPORT="/home/admin1/redhat/relatorios/sintetico/reportSintetico"

JAVA_PKG="br.gov"
BUSCA_FILE=busca.txt
PACOTE_FILE=pacote.txt
WINDUP_LOG=windup.log

function check_error {
	if [[ "$?" != 0 ]]; then
		echo -ne "\033[0;31m Error! \033[0m"
		echo
		exit 1;
	else
		echo -ne "\033[0;32m Done! \033[0m"
		echo
	fi
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


function clearSource {
	for ext in "*.zip" "*.ear" "*.war" "*.class" "*.java" "*.java.*" "*.jsp" "*.sql" "*.ser" "*.cpp""*.h" "*.c" "*.exe" "*.jar" "*.pdf";
	do
		find $1 -name $ext -exec rm -i {} \;
	done
}

# Parametros
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function windupReport() {
	java -jar $WINDUP_PATH/windup-cli.jar -input $1 -source true -javaPkgs $JAVA_PKG -output $WINDUP_REPORT/$2  >> $WINDUP_LOG &
	
	while [[ $(ps aux | grep "windup") ]]
	do
		p=$(tail -1 $WINDUP_LOG | grep "Interrogating" | cut -d" " -f5,6,7)
		echo -ne "Gerando relatorio windup... $p"\\r
		#sleep 2
	done

	check_error
}

# Parametros
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function tattletaleReport() {
	echo -n "Gerando relatorio tattletale..."
	java -jar $TATTLETALE_PATH/tattletale.jar $1 $TATTLETALE_REPORT/$2
	check_error
}

# Parametros
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function treeSimpleReport() {
	echo -n "Gerando relatorio tree simple..."
	tree -AC $1 > $TREE_REPORT/$2.tree
	check_error
}

# Parametros
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function treeFullReport() {
	echo -n "Gerando relatorio tree full..."
	tree -ifs $1 > $TREE_REPORT/$2-fullpath.tree
	check_error
}

# Parametros
# $1 = $sistema_path (path do sistema)
# $2 = $sistema (nome do sistema)
function sinteticoReport() {
	mkdir -p $SINTETICO_REPORT
	echo -e "############################ \033[0;31m $2 \033[0m ############################\n" > $SINTETICO_REPORT/$2
	
	# Arquivos descritores
	echo -n "Verificando arquivos descritores..."
	for arq in "Maven#pom.xml" "Ant#build*.xml" "Jasper Report#*.jrxml" "Sun Web Descriptor#sun-web.xml" "EJB Descriptor#ejb-jar.xml" "Log4J#log4j.xml" \
"Log4J Prop#log4j.properties" "EAP Application#application.xml" "JSF#faces-config*.xml" "Portlet#portlet.xml" "WAR Application#web.xml" "Struts#struts-config.xml" \
"Bean Validation#validation.xml" "JBoss xml#jboss.xml" "JBoss Web#jboss-web.xml" "JBoss app xml#jboss-app.xml" "Validation Rules#validation-rules.xml" \
"JBoss Service#jboss-service.xml" "Persistence.xml#persistence.xml" "Services.xml#services.xml" "TLD#*.tld" "Dist#dist.xml" ;
	do	
		tec=$(echo $arq | cut -d"#" -f1)
		arqDesc=$(echo $arq | cut -d"#" -f2)

		echo -n "$tec: " >> $SINTETICO_REPORT/$2
		exist $1 "$arqDesc" >> $SINTETICO_REPORT/$2
	done
	check_error
	
	# Quantidade de frameworks
	echo -n "Verificando quantidade de frameworks..."
	echo "\n==> Frameworks" >> $SINTETICO_REPORT/$2
	while read linha 
	do
		result=$(fgrep -R "$linha" $WINDUP_REPORT/$2/index.html | cut -d"/" -f2 | wc -l)
  	
   		if [ $result != "0" ]; then
   			echo -e "$linha: \033[0;31m$result\033[0m" >> $SINTETICO_REPORT/$2
   		fi
	done < $BUSCA_FILE
	check_error

	# Dependencias
	echo -n "Verificando dependencias..."
	echo -e "\n==> Dependencias:" >> $SINTETICO_REPORT/$2
	for dep in $(cat $TATTLETALE_REPORT/$2/graphviz/index.html | sed 's/<[^>]*>//g' | sed -r 's/&nbsp;//' | grep .jar | tr -d ' '); do
		echo -e "\033[0;32m $dep \033[0m" >> $SINTETICO_REPORT/$2
	done
	check_error
	
	# JARs duplicados
	echo -n "Verificando JARs duplicados..."
	echo -e "\n==> JARs com classes em comum/duplicados:" >> $SINTETICO_REPORT/$2
	for mul in $(cat $TATTLETALE_REPORT/$2/multiplejars/index.html | sed 's/<[^>]*>//g' | sed -r 's/&nbsp;//' | grep .jar | tr -d ' ' | sort | uniq | tr -d ','); do
		echo -e "\033[0;32m $mul \033[0m" >> $SINTETICO_REPORT/$2
	done
	check_error
	
	# JARs nao utilizados
	echo -n "Verificando JARs nao utilizados..."
	echo -e "\n==> JARs não utilizados:" >> $SINTETICO_REPORT/$2
	for mul in $(cat $TATTLETALE_REPORT/$2/unusedjar/index.html | sed 's/<[^>]*>//g' | sed -r 's/&nbsp;//' | tr -d ' ' | grep -B1 No | tr -d '-' | grep -v No | sed '/^$/d'); do
		echo -e "\033[0;32m $mul \033[0m" >> $SINTETICO_REPORT/$2
	done
	check_error

	# Classes que utilizam cada framework
	echo -n "Verificando qual classe utiliza qual framework..."
	echo -e "\n==> Classe que usam os frameworks:" >> $SINTETICO_REPORT/$2
	while read linha 
	do
		declare -a result=$(cat $WINDUP_REPORT/$2/index.html | grep -C 2 "Classification: $linha" | grep "a href=" | cut -d'<' -f15 | cut -d'"' -f2 | sed 's/\.html$//g')
		if [[ -n $result ]]; then
   			echo -e "\033[0;32m $linha  \033[0m" >> $SINTETICO_REPORT/$2
			
			printf -- '%s\n\n\n\n' "${result[@]}" >> $SINTETICO_REPORT/$2

   		fi
	done < $BUSCA_FILE
	check_error

	# JARs já fornecidos pelo servidor de aplicação
	echo -e "\n==> JARs já fornecidos pelo JBoss:" >> $SINTETICO_REPORT/$2
	echo -n "Verificando JARs já fornecidos pelo JBoss..."
	for jar in "asm" "cal10n" "guava" "h2" "activation" "jsf-api" "hibernate-jpa" "connector-api" "el-api" "validation-api" "jaxrs-api" "ejb-api" "annotations-api" "jacc-api" "jaspi-api" "javax.inject" "mail" "jsr181-api" "transaction-api" "jaxb-api" "saaj-api" "jaxws-api" "jaxrpc-api" "jaxr-api" "rmi-api" "wsdl4j" "jstl-api" "servlet-api" "jsp-api" "interceptors-api" "cdi-api" "jad-api" "jms-api" "xom" "codemodel" "jsf-impl" "jaxb-xjc" "jaxb-impl" "saaj-impl" "txw2" "istack-commons" "xsom" "relaxngDatatype" "jcip-annotations" "infinispan-core" "infinispan-client-hotrod" "infinispan-cachestore-jdbc" "infinispan-cachestore-remote" "opensaml" "xmltooling" "openws" "snakeyaml" "javassist" "jgroups" "jackson" "jettison" "woodstox" "stax2" "org.osgi" "jaxen" "hibernate-entitymanager" "hibernate-core" "hibernate-infinispan" "hibernate-commons-annotations" "hibernate-envers" "hibernate-validator" "hornetq" "jacorb" "jansi" "picketlink" "antlr" "aesh" "marshalling" "metadata" "netty" "xnio" "slf4j" "jaxb" "cxf" "staxmapper" "jms" "ironjacamar" "httpserver" "resteasy" "jaxr" "mod_cluster" "jpa" "shrinkwrap" "common-beans" "weld" "joda" "apache-mime4j" "wss4j" "httpclient" "httpmime" "httpcore" "xerces" "commons-io" "commons-cli" "commons-pool" "commons-codec" "commons-lang" "commons-beanutils" "commons-configuration" "commons-collections" "xalan" "xts" "uddi" "velocity" "neethi" "dom4j" "picketbox" "rngom" "scannotation" "slf4j" "jdom" "asm" "hibernate-search" "richfaces" "seam" "snowdrop" "struts" "arquillian" "gwt" "spring" "icefaces" "grails";
	do
		grep -e ".*$jar.*jar$" $TREE_REPORT/$2-fullpath.tree | cut -d"]" -f2 | tr -d ' ' >> $SINTETICO_REPORT/$2
	done
	check_error
}
	

# Gerando arquivos de novas regras
echo -n "Verificando pacotes ainda não existentes no windup..."
fgrep -R "import " $SISTEMAS_PATH | grep -v "@import" | grep -v "<import" |  grep -v "import javax" | grep -v "import $JAVA_PKG" | grep -v "import java." | cut -d":" -f 2 | sort | uniq | less > $PACOTE_FILE
check_error

echo "###############################################################################"
echo "#### Pare tudo! Abra o arquivo pacotes.txt e crie as novas regras do windup ####"
echo "###############################################################################"
echo "Enter para prosseguir"
read lixo

echo -n "Criando busca.txt "
cat $WINDUP_PATH/rules/extensions/extension-example.windup.xml | grep 'java-classification source-type="IMPORT"' | cut -d'=' -f4 | cut -d'"' -f2 > $BUSCA_FILE
echo "EJB 1.x/2.x - Home Interface" >> $BUSCA_FILE
echo "EJB 1.x/2.x - Remote Interface" >> $BUSCA_FILE
echo "EJB 1.x/2.x - Entity Bean" >> $BUSCA_FILE
echo "EJB 1.x/2.x - Session Bean" >> $BUSCA_FILE
echo "EJB 2.x - Local Home" >> $BUSCA_FILE
echo "EJB 2.x - Local Object" >> $BUSCA_FILE
echo "EJB 2.x - Message Driven Bean" >> $BUSCA_FILE
echo "EJB 3.x - Message Driven Bean" >> $BUSCA_FILE
echo "EJB 3.x - Local Session Bean Interface" >> $BUSCA_FILE
echo "EJB 3.x - Remote Session Bean Interface" >> $BUSCA_FILE
echo "EJB 3.x - Stateless Session Bean" >> $BUSCA_FILE
echo "EJB 3.x - Stateful Session Bean" >> $BUSCA_FILE
echo ".jsp" >> $BUSCA_FILE
echo ".xhtml" >> $BUSCA_FILE
check_error

# Limpa fontes de arquivos invalidos e vazios
echo -n "Limpando fontes (arquivos vazios e com pacote default)..."
find $SISTEMAS_PATH -name *.java -type f -empty -exec rm -i {} \;
for filerm in $(find $SISTEMAS_PATH -name *.java -exec grep -L package {} \;)
do
	rm -i $filerm
done
check_error

# Gera relatorio
for sistema_path in $(find $SISTEMAS_PATH -maxdepth 1 -type d | sed -e "1d")
do
	sistema=$(echo $sistema_path | cut -d'/' -f6)
	
	echo -e "\n\n### $sistema ###"

	windupReport $sistema_path $sistema

	tattletaleReport $sistema_path $sistema
	
	treeSimpleReport $sistema_path $sistema

	treeFullReport $sistema_path $sistema

	sinteticoReport $sistema_path $sistema
	
done

# Limpa dados
#clearSource $WINDUP_REPORT

#limpa arquivos tmp
rm $PACOTE_FILE
rm $BUSCA_FILE
rm $WINDUP_LOG

# zipa relatório
#tar -jcvf relatorio.tar.bz2 $WINDUP_REPORT
