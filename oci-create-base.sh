#!/bin/bash
set +x

read -p "Set Profile =" PROFILE
read -p "Comparment RAIZ =" COMPARMENT_RAIZ

count=0
countsubpriv=0
countsubpub=0

function subnet-priv() {

    while read -r linesubpriv; do
        export PRIVSUB=$(echo $linesubpriv | awk '{print $1}')
        export IPPRIVSUB=$(echo $linesubpriv | awk '{print $2}')
        # export DECSUB=$(echo $linesubpriv|awk '{print $2}')
        echo "SUBPRIV-COMP="$COMP
        echo "SUBPRIV-VCN="$VCN
        echo "SUBPRIV ="$PRIVSUB
        echo "SUBPRIV ="$IPPRIVSUB

        echo "criando Security List SL_$PRIVSUB------------" 

        export Valida=$(oci network security-list list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name","security-list-ids":"security-list-ids"}' --profile $PROFILE | grep SL_$PRIVSUB | awk '{print $4}')

        if [[ ! -n $Valida ]]; then
          echo "Securiry List nao existe"
          oci network security-list create --compartment-id $COMP --vcn-id $VCN --display-name SL_$PRIVSUB --egress-security-rules '[{"destination": "0.0.0.0/0", "protocol": "6", "isStateless": true }]' --ingress-security-rules '[{"source": "'$IPPRIVSUB'", "protocol": "6", "isStateless": true}]' --profile $PROFILE
         else
            echo "Securiry List LIVRE ja existe"
        fi

        export SLprivID=$(oci network security-list list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name","security-list-ids":"security-list-ids"}' --profile $PROFILE | grep SL_$PRIVSUB | awk '{print $4}')

        echo "criando Route RT_$PRIVSUB------------" 
        
        export ValidaRT=$(oci network route-table list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep         RT_$PRIVSUB | awk '{print $4}')

         if [[ ! -n $ValidaRT ]]; then
               echo "Route LIVRE nao existe "
               oci network route-table create --compartment-id $COMP --vcn-id $VCN --display-name RT_$PRIVSUB --route-rules '[{"cidrBlock":"0.0.0.0/0","networkEntityId":"'$NATG'"}]' --profile $PROFILE
           else
               echo "Route LIVRE ja existe"
         fi      

        export RTprivID=$(oci network route-table list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep RT_$PRIVSUB | awk '{print $4}')

        echo "criando Subnet $PRIVSUB------------" 

        oci network subnet create --cidr-block $IPPRIVSUB --compartment-id $COMP --vcn-id $VCN --route-table-id $RTprivID --prohibit-public-ip-on-vnic true --security-list-ids '['\"$SLprivID\"']' --display-name $PRIVSUB --profile $PROFILE

        export SubnetprivID=$(oci network subnet list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep $PRIVSUB | awk '{print $4}')

        echo "SubnetID=" $SubnetprivID
        echo "Rota RT_$PRIVSUB ID=" $RTprivID
        echo "Security List SL_$PRIVSUB ID =" $SLprivID

        if [ $countsubpriv -eq 100 ]; then
            echo "linha $countsubpriv"
        fi

        count=$((count + 1))

    done < $NOME-subnet-priv.env
}

function subnet-pub() {
    while read -r linesubpub; do
        export PUBSUB=$(echo $linesubpub | awk '{print $1}')
        export IPPUBSUB=$(echo $linesubpub | awk '{print $2}')
       
        echo "SUBPUB-COMP="$COMP
        echo "SUBPUB-VCN="$VCN
        echo "SUBPUB = "$PUBSUB
        echo "SUBPUB =" $IPPUBSUB

        echo "criando Security List SL_$PUBSUB------------" 

        oci network security-list create --compartment-id $COMP --vcn-id $VCN --display-name SL_$PUBSUB --egress-security-rules '[{"destination": "0.0.0.0/0", "protocol": "6", "isStateless": true }]' --ingress-security-rules '[{"source": "'$IPPUBSUB'", "protocol": "6", "isStateless": true}]' --profile $PROFILE

        export SLID=$(oci network security-list list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name","security-list-ids":"security-list-ids"}' --profile $PROFILE | grep SL_$PUBSUB | awk '{print $4}')

        echo "Security List SL_$PUBSUB ID =" $SLID

        echo "criando Route RT_$PUBSUB------------" 
     
        oci network route-table create --compartment-id $COMP --vcn-id $VCN --display-name RT_$PUBSUB --route-rules '[{"cidrBlock":"0.0.0.0/0","networkEntityId":"'$IG'"}]' --profile $PROFILE

        export RTID=$(oci network route-table list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep RT_$PUBSUB | awk '{print $4}')

        echo "Rota RT_$PUBSUB List -----  RTID =" $RTID

        echo "criando Subnet $PUBSUB------------" 

        oci network subnet create --cidr-block $IPPUBSUB --compartment-id $COMP --vcn-id $VCN --route-table-id $RTID --security-list-ids '['\"$SLID\"']' --display-name $PUBSUB --profile $PROFILE

        export SubnetID=$(oci network subnet list --compartment-id $COMP --vcn-id $VCN --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep $PUBSUB | awk '{print $4}')


        echo "SubnetID=" $SubnetID
        echo "Rota RT_$PUBSUB ID=" $RTID
        echo "Security List SL_$PUBSUB ID =" $SLID


        if [ $countsubpub -eq 100 ]; then
            echo "linha $countsubpub"
        fi

        count=$((count + 1))

    done < $NOME-subnet-pub.env
}

while read -r line; do

    export NOME=$(echo $line | awk '{print $1}')
    export COMPNAME=$(echo $line | awk '{print $1}')
    export VCNRANGE=$(echo $line | awk '{print $2}')
    echo "Compartment = " $COMPNAME
    echo "Range VCN = " $VCNRANGE
    echo "Compartment = " $NOME

    oci iam compartment create --name $NOME --compartment-id $COMPARMENT_RAIZ --description "Compartment $COMPNAME" --profile $PROFILE

    sleep 25; #Tempo necessario para validacao da criacao do compartment
   
    export COMP=$(oci iam compartment list --output table --query 'data [*].{id:id,name:name}' --profile $PROFILE | grep $NOME | awk '{print $2}')

    echo "Compartment id = "$COMP

    echo "criando VCN ------------" 
    oci network vcn create --compartment-id $COMP --cidr-block $VCNRANGE --display-name VCN-$COMPNAME --profile $PROFILE

    export VCN=$(oci network vcn list --compartment-id $COMP --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep VCN-$COMPNAME | awk '{print $4}')

    echo "criando local-peering-gateway ------------" 
   oci network local-peering-gateway create --compartment-id $COMP --vcn-id $VCN --display-name LPG-VCN-$COMPNAME --profile $PROFILE

    export LPG=$(oci network local-peering-gateway list --compartment-id $COMP --vcn-id $VCN  --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep LPG-VCN-$COMPNAME  | awk '{print $4}')
     
    echo "criando internet-gateway  ------------"  
    oci network internet-gateway create --compartment-id $COMP --vcn-id $VCN --is-enabled true --display-name IG-$COMPNAME --profile $PROFILE

    export IG=$(oci network internet-gateway list  --compartment-id $COMP --vcn-id $VCN  --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep  IG-$COMPNAME | awk '{print $4}')

    echo "criando nat-gateway ------------"  

    oci network nat-gateway create --compartment-id $COMP --vcn-id $VCN  --display-name NATG-$COMPNAME --profile $PROFILE
    export NATG=$(oci network nat-gateway list  --compartment-id $COMP --vcn-id $VCN  --output table --query 'data [*].{id:id,"display-name":"display-name"}' --profile $PROFILE | grep NATG-$COMPNAME | awk '{print $4}')

   echo "VCN-id = " $VCN
   echo "LPG-id = " $LPG
   echo "IG-id = " $IG
   echo "NATG-id = " $NATG
   echo "SEG-id = " $SEG
   echo "Compartment-NAME = " $COMPNAME

    subnet-priv
    subnet-pub

    if [ $count -eq 100 ]; then
        echo "linha $count"
    fi

    count=$((count + 1))

done < compartment.env
