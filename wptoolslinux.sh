#!/bin/bash

#########################################################################
## WP Tools LINUX *NEW* Updated: 06.05.2016                            ##
## Written for daily wordpress tasks, maintenance, support, hardening  ##
#########################################################################

# CHANGELOG - 20 SEPT 2026 - Confirmed install works
# Script assumes certain system standards based on centos may not work as desired for all systems without tweaks
# use at own rsik
# dumping as archival code / use for someone else




if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` [somestuff]"
  exit 0
fi

echo "#############WORDPRESS TOOLS *LINUX* USE WITH CAUTION#################"

PS3='Please choose an option from above 1-12: '
options=("New WP Install" "Replace WP Core (Preserve Config)" "Replace WP Plugins" "Replace WP Themes" "Backup Wordpress" "Upgrade to Latest WP Core" "Harden Wordpress 6G FW" "Findbot Shell Scan" "Scan Uploads Dir" "Lock/Unlock Sites" "PHP Header/Base64 Clean" "Quit")
select opt in "${options[@]}"
do
    case $opt in


"New WP Install")

echo "Please enter Wordpress site/folder to create"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Site/Folder!"
        done

if [ -d $getwp ] ; then

        echo "Directory/Site already exists!"
        echo "Exiting..."
exit 1

fi

echo "Create and Install WP to root of $getwp? (y/n)"
read -e getdir

if [ "$getdir" == n ] ; then

echo "Please enter Wordpress site/folder to create"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Site/Folder!"
        done

fi

echo "Will create and install to $getwp"

echo "Do you want to create a new MySQL database? (y/n)"
        read -e setupmysql
        if [ "$setupmysql" == y ] ; then
        echo "MySQL Admin User: "
        read -e mysqluser
        echo "MySQL Admin Password: "
        read -s mysqlpass
        echo "MySQL Host (Enter for default 'localhost'): "
        read -e mysqlhost
                mysqlhost=${mysqlhost:-localhost}
fi
echo "WP Database Name: "
read -e dbname
echo "WP Database User: "
read -e dbuser
echo "WP Database Password: "
read -s dbpass
echo "WP Database Table Prefix [numbers, letters, and underscores only] (Enter for default 'wp_'): "
read -e dbtable
        dbtable=${dbtable:-wp_}

echo "Proceed with the install of $getwp (y/n)"
read -e run
if [ "$run" == y ] ; then
        if [ "$setupmysql" == y ] ; then
                echo "Creating the database."
                #login to MySQL, add database, add user and grant permissions
                dbsetup="create database $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@$mysqlhost IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;"
                mysql -u $mysqluser -p$mysqlpass -e "$dbsetup"
                if [ $? != "0" ]; then
                        echo "Database creation failed. (Check user and pw or service is started) Aborting..."
                        exit
                fi
        fi
        echo "Creating Directory $getwp"
        mkdir -p $getwp
        #download wordpress
        echo "Downloading Wordpress..."
        curl -sS -O https://wordpress.org/latest.tar.gz
        #unzip wordpress
        echo "Unpacking..."
        tar -zxf latest.tar.gz
        #move /wordpress/* files to this dir
        echo "Moving Core..."
        mv wordpress/* $getwp/
        echo "Configuring DB..."
        #create wp config
        mv $getwp/wp-config-sample.php $getwp/wp-config.php
        #set database details with perl find and replace
        perl -pi -e "s'database_name_here'"$dbname"'g" $getwp/wp-config.php
        perl -pi -e "s'username_here'"$dbuser"'g" $getwp/wp-config.php
        perl -pi -e "s'password_here'"$dbpass"'g" $getwp/wp-config.php
        perl -pi -e "s/\'wp_\'/\'$dbtable\'/g" $getwp/wp-config.php
        #set WP salts
        perl -i -pe'
          BEGIN {
            @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
            push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
            sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
          }
          s/put your unique phrase here/salt()/ge
        ' $getwp/wp-config.php
        echo "Cleaning up my mess..."
        #remove wordpress/ dir
        rm -rf wordpress
        #remove zip file
        rm -f latest.tar.gz

        ##SET PERMISSIONS
        ## START GET APPROPRIATE USER INFO


                ApacheUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`
                GroupUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`


        ## START - Change Ownership

        echo "Updating Ownership Permissions to $ApacheUser:$GroupUser"
        echo  "If you would like to change press 'n' If this is OK, press 'y'"

        read own
        if [ $own == "y" -o $own == "Y" -o $own == "yes" -o $own == "YES" ]; then

                chown -R $ApacheUser:$GroupUser $getwp

                echo "chown successful"

        else

                echo "Please Enter Apache/System User and Group In the following format User:Group"
                echo ""
                while read -p 'User:Group:' ans && [[ -z "$ans" ]] ; do
                         echo "Please enter Userand Group!"
                 done

                 echo ""
                 printf "You've entered $ans is this correct?"
                 echo ""

                 read ans1
                 if [ $ans1 == "y" -o $ans1 == "Y" -o $ans1 == "yes" -o $ans1 == "YES" ]; then

                         chown -R $ans $getwp

                         echo "chown successful"

                 else

                         echo "Please RE-Enter Apache/System User and Group In the following format User:Group"

                         while read -p 'User:Owner:' ans2 && [[ -z "$ans2" ]] ; do

                                  echo "Please enter User and Group!"
                          done

                          chown -R $ans2 $getwp

                          echo "chown successful"

                  fi
          fi

          ## END - Change Ownership
printf "Updating Wordpress Directories Permissions 755\n"
find $getwp -type d -exec chmod 755 {} \;

sleep 2

printf "Updating Wordpress Files to 644 \n"
find $getwp -type f -exec chmod 644 {} \;

## END - Complete Permission changes ##


        echo ""
        echo "Installation complete!"
        echo "Please visit $getwp to finish installation"
        echo ""
        echo ""
        echo "###Database DETAILS:###"
        echo "Database Host: $mysqlhost"
        echo "Database: $dbname"
        echo "Database Name: $dbname"
        echo "Database User: $dbuser"

fi

;;

        "Replace WP Core (Preserve Config)")


echo "Please enter Wordpress site (just domain)"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Directory!"
        done

if [ -f $getwp/wp-config.php ] ; then
wpsite=`find $getwp -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

else

#wpsite1=`find $wpsite -type f -name wp-config.php`
wpsite=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1,2`
wpsite2=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

fi
read -p "Wordpress install for $getwp found at $wpsite. Is this correct? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    echo "EXITING..."
    exit 1
  else
    echo
    echo "PROCEEDING.."
  fi


       echo "This will replace current version of WP Core as well as remove all files not part of WP"

        TIME=`date +%m%d%H%M%SZ`


        WPVERS=`cat $wpsite/wp-includes/version.php | grep "wp_version =" | cut -d= -f2 | tr -d \' | tr -d \; | xargs`

echo -n "Would you like to include uploads directory in backup? (y/n) : "
read answercleaning1
if [ $answercleaning1 == "y" -o $answercleaning1 == "Y" -o $answercleaning1 == "yes" -o $answercleaning1 == "YES" ]; then
echo ""

echo "Backing up $getwp version $WPVERS including uploads..."

tar -zcf $wpsite.$TIME.tar.gz $wpsite

SIZE=`du -hs $wpsite.$TIME.tar.gz`

echo "Backup Completed $SIZE"

else
echo ""
echo "Backing up $getwp version $WPVERS EXCLUDING uploads..."
sleep 1

tar -zcf $wpsite.$TIME.tar.gz --exclude="$wpsite/wp-content/uploads" $wpsite

SIZE1=`du -hs $wpsite.$TIME.tar.gz`

echo "Backup Completed $SIZE1"

fi


        echo "temporarily moving $wpsite to $wpsite.bak1"

        if [ -d $wpsite.bak1 ] ; then
                echo "Warning! $wpsite.bak1 exists"
                echo "Rotating $wpsite.bak1 to $wpsite.$TIME"

                mv $wpsite.bak1 $wpsite.$TIME
                echo ""
                echo "done."
                echo "Moving $wpsite to $wpsite.bak1"
                mv $wpsite $wpsite.bak1
                echo ""
                echo "done."

        else

                mv $wpsite $wpsite.bak1
                echo ""
                echo "done."

        fi

        rm -rf wordpress_web
        echo ""
        echo "Downloading Wordpress $WPVERS"
        curl --create-dirs -o wordpress_web/wordpress.zip https://wordpress.org/wordpress-$WPVERS.zip

        echo ""
        echo "decompressing wordpress $WPVERS"
	
	#CHECK IF DOWNLOAD COMPLETED SUCCESSFULLY.
        if [ ! -f wordpress_web/wordpress.zip ] ; then
        echo "Could not download wordpress. Exiting"
        echo "Moving back $wpsite.bak1 to $wpsite"
        mv $wpsite.bak1 $wpsite
        echo "done"
        exit 1
        else

        unzip -qd wordpress_web wordpress_web/wordpress.zip

        echo ""
        echo "cleaning up..."
        echo ""
        echo "removing wordpress.zip"
        rm -f wordpress_web/wordpress.zip
        echo ""
        echo "removing wp-content folder from download"
        rm -rf wordpress_web/wordpress/wp-content
        echo ""
        echo "removing wp-config-sample.php"
        rm wordpress_web/wordpress/wp-config-sample.php
        echo "done."
        echo ""
        echo ""
        echo "moving wordpress_web/wordpress $wpsite"
        mv wordpress_web/wordpress $wpsite
        echo ""
        echo "Copying $wpsite.bak1/wp-config.php $wpsite/"
        cp -R -p $wpsite.bak1/wp-config.php $wpsite/
        echo ""
        echo "Copying $wpsite.bak1/wp-content $wpsite/"
        cp -R -p $wpsite.bak1/wp-content $wpsite/
        echo "Copying $wpsite.bak1/.htaccess $wpsite/"
        cp -R -p $wpsite.bak1/.htaccess $wpsite/
        echo ""
        echo "done."
        echo ""
        echo "removing temp wordpress dir"
        echo ""
        rm -rf wordpress_web
        echo "Please check Wordpress Site - Visit $wpsite in browser"
        echo ""
        echo "If $wpsite is loading without errors please hit [y] to remove .bak1 directory (tar.gz backup will remain)"
        read tall
        if [ $tall == "y" -o $tall == "Y" -o $tall == "yes" -o $tall == "YES" ]; then

rm -rf "$wpsite.bak1"

        else

                echo "Keeping $wpsite.bak1"

        fi

        ##SET PERMISSIONS
        ## START GET APPROPRIATE USER INFO
        echo "Automatically pulling apache user from /etc/httpd/conf/httpd.conf
        echo "If fail, on 
        

                ApacheUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`
                GroupUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`


        ## START - Change Ownership

        echo "Updating Ownership Permissions to $ApacheUser:$GroupUser"
        echo  "If you would like to change user and group hit 'n' If the above is OK, press 'y'"

        read own
        if [ $own == "y" -o $own == "Y" -o $own == "yes" -o $own == "YES" ]; then

                chown -R $ApacheUser:$GroupUser $wpsite

                echo "chown successful"

        else

                echo "Please Enter Apache/System User and Group In the following format User:Group"
                echo ""
                while read -p 'User:Group:' ans && [[ -z "$ans" ]] ; do
                         echo "Please enter Userand Group!"
                 done

                 echo ""
                 printf "You've entered $ans is this correct?"
                 echo ""

                 read ans1
                 if [ $ans1 == "y" -o $ans1 == "Y" -o $ans1 == "yes" -o $ans1 == "YES" ]; then

                         chown -R $ans $wpsite

                         echo "chown successful"

                 else

                         echo "Please RE-Enter Apache/System User and Group In the following format User:Group"

                         while read -p 'User:Owner:' ans2 && [[ -z "$ans2" ]] ; do

                                  echo "Please enter User and Group!"
                          done

                          chown -R $ans2 $wpsite

                          echo "chown successful"

                  fi
          fi
	fi
          ## END - Change Ownership
printf "Updating Wordpress Directories Permissions 755\n"
find $wpsite -type d -exec chmod 755 {} \;

sleep 2

printf "Updating Wordpress Files to 644 \n"
find $wpsite -type f -exec chmod 644 {} \;

## END - Complete Permission changes ##


;;

######################################################################################################
#######################################REPLACE WP PLUGINS #2

        "Replace WP Plugins")

TIME=`date +%m%d%H%M%SZ`

echo "Please enter Wordpress site (just domain)"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Directory!"
        done

if [ -f $getwp/wp-config.php ] ; then
wpsite=`find $getwp -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

else

#wpsite1=`find $wpsite -type f -name wp-config.php`
wpsite=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1,2`
wpsite2=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

fi
read -p "Wordpress install for $getwp found at $wpsite. Is this correct? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    echo "EXITING..."
    exit 1
  else
    echo
    echo "PROCEEDING.."
  fi

        ##SET PERMISSIONS
        ## START GET APPROPRIATE USER INFO


                ApacheUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`
                GroupUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`


        ## START - Change Ownership

        echo "Updating Ownership Permissions to $ApacheUser:$GroupUser"
        echo  "If you would like to change press 'n' If this is OK, press 'y'"

        read own
        if [ $own == "y" -o $own == "Y" -o $own == "yes" -o $own == "YES" ]; then

#                chown -R $ApacheUser:$GroupUser $wpsite
#                echo "chown successful"
PERM=$ApacheUser:$GroupUser
echo "Permissions will be set for $PERM"
        else

                echo "Please Enter Apache/System User and Group In the following format User:Group"
                echo ""
                while read -p 'User:Group:' ans && [[ -z "$ans" ]] ; do
                         echo "Please enter Userand Group!"
                 done

                 echo ""
                 printf "You've entered $ans is this correct?"
                 echo ""

                 read ans1
                 if [ $ans1 == "y" -o $ans1 == "Y" -o $ans1 == "yes" -o $ans1 == "YES" ]; then

#                         chown -R $ans $wpsite
#                         echo "chown successful"
PERM=$ans
echo "Permissions will be set for $PERM"
                 else

                         echo "Please RE-Enter Apache/System User and Group In the following format User:Group"

                         while read -p 'User:Owner:' ans2 && [[ -z "$ans2" ]] ; do

                                  echo "Please enter User and Group!"
                          done

#                          chown -R $ans2 $wpsite
#                          echo "chown successful"
PERM=$ans2
echo "Permissions will be set for $PERM"
fi
fi

#BACKUP PLUGINS DIR
        echo "Backing up Plugins Directory..."
        echo ""
        tar -zcf $wpsite/wp-content/plugins.$TIME.tar.gz $wpsite/wp-content/plugins
        echo ""
        echo "done."
        echo ""
        echo "temporarily moving $wpsite plugins to $wpsite/wp-content/plugins.bak1"

        if [ -d $wpsite/wp-content/plugins.bak1 ] ; then
        echo "Warning! $wpsite/wp-content/plugins.bak1 exists"
        echo "Rotating $wpsite/wp-content/plugins.bak1 to plugins.$TIME"
        mv $wpsite/wp-content/plugins.bak1 $wpsite/wp-content/plugins.$TIME
        echo "Moving $wpsite plugins to plugins.bak1"
        mv $wpsite/wp-content/plugins $wpsite/wp-content/plugins.bak1
       echo ""
        mkdir $wpsite/wp-content/plugins
        chown $PERM $wpsite/wp-content/plugins

else

        echo "Backing up $wpsite plugins"
        mv $wpsite/wp-content/plugins $wpsite/wp-content/plugins.bak1
        echo "done. "
        mkdir $wpsite/wp-content/plugins
        chown $PERM $wpsite/wp-content/plugins
fi

        echo "Gathering list of plugins"
        #######PULL PLUGIN DIR LIST
##PLUGIN LIST MAKE SURE CUT IS RIGHT
#        ls -d $wpsite/wp-content/plugins.bak1/*/ | cut -f5 -d'/' > pluginlist

if [ -f $getwp/wp-config.php ] ; then
ls -d $wpsite/wp-content/plugins.bak1/*/ | cut -f4 -d'/' > pluginlist

else

#wpsite1=`find $wpsite -type f -name wp-config.php`
ls -d $wpsite/wp-content/plugins.bak1/*/ | cut -f5 -d'/' > pluginlist

fi


echo "verifying if all plugins are available in wp repo"

# verify which plugins available are in wordpress repo. if they arent, remove from list.

if [ -f pluginlistremoved ] ; then
rm -f pluginlistremoved
fi
       for pinstall in $(cat pluginlist) ; do

curl -sL -w "%{http_code} %{url_effective}\\n" "URL" -o /dev/null "https://wordpress.org/plugins/$pinstall" -o /dev/null > htcode

catcode=`tail -1 htcode | cut -c1,2,3`


if [ $catcode = "200" ]; then

echo ""
#echo "$catcode $pinstall available in WP repo. Will reinstall without issue"

else

echo "$pinstall not found in WP repo. Removing from list to reinstall"

echo $pinstall >> pluginlistremoved
sed -i s/$pinstall// pluginlist
fi
done




# install plugins



        echo "Installing plugins.."

       for pinstall in $(cat pluginlist) ; do

   #########Check if plugin download  already exists
   if [ -d $pinstall ]
   then
             echo ""
               rm -rf $pinstall
                 rm -f $pinstall.zip
          fi

wget -q --no-check-certificate https://downloads.wordpress.org/plugin/$pinstall.zip | tr -d '\r'

unzip -q $pinstall.zip

mkdir -p $wpsite/wp-content/plugins/$pinstall

cp -r $pinstall/* $wpsite/wp-content/plugins/$pinstall

#clean up
if [ -f $pinstall.zip ]
then

chown -R $PERM $wpsite/wp-content/plugins/$pinstall

echo "$pinstall SUCCESS. Permissions $PERM applied"

rm $pinstall.zip
rm -rf $pinstall
rm -f $pinstall
echo ""

else
        echo "Possible Failure. Please test site; and restore from backup if necessary"

fi

done


coun=`cat pluginlist | grep -v -e '^$' | wc -l`
echo ""
echo "$coun plugins successfully re-installed. If you have plugins that were not installed due to errors, place them back in plugins directory from the plugins.bak1 directory"
rm -f pluginlist
echo ""

;;


##########################################################################################################
##################################################### REPLACE WP THEMES #3
        "Replace WP Themes")

TIME=`date +%m%d%H%M%SZ`

echo "Please enter Wordpress site (just domain)"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Directory!"
        done

if [ -f $getwp/wp-config.php ] ; then
wpsite=`find $getwp -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

else

#wpsite1=`find $wpsite -type f -name wp-config.php`
wpsite=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1,2`
wpsite2=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

fi
read -p "Wordpress install for $getwp found at $wpsite. Is this correct? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    echo "EXITING..."
    exit 1
  else
    echo
    echo "PROCEEDING.."
  fi

        ##SET PERMISSIONS
        ## START GET APPROPRIATE USER INFO


                ApacheUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`
                GroupUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`


        ## START - Change Ownership

        echo "Updating Ownership Permissions to $ApacheUser:$GroupUser"
        echo  "If you would like to change press 'n' If this is OK, press 'y'"

        read own
        if [ $own == "y" -o $own == "Y" -o $own == "yes" -o $own == "YES" ]; then

#                chown -R $ApacheUser:$GroupUser $wpsite
#                echo "chown successful"
PERM=$ApacheUser:$GroupUser
echo "Permissions will be set for $PERM"
        else

                echo "Please Enter Apache/System User and Group In the following format User:Group"
                echo ""
                while read -p 'User:Group:' ans && [[ -z "$ans" ]] ; do
                         echo "Please enter Userand Group!"
                 done

                 echo ""
                 printf "You've entered $ans is this correct?"
                 echo ""

                 read ans1
                 if [ $ans1 == "y" -o $ans1 == "Y" -o $ans1 == "yes" -o $ans1 == "YES" ]; then

#                         chown -R $ans $wpsite
#                         echo "chown successful"
PERM=$ans
echo "Permissions will be set for $PERM"
                 else

                         echo "Please RE-Enter Apache/System User and Group In the following format User:Group"

                         while read -p 'User:Owner:' ans2 && [[ -z "$ans2" ]] ; do

                                  echo "Please enter User and Group!"
                          done

#                          chown -R $ans2 $wpsite
#                          echo "chown successful"
PERM=$ans2
echo "Permissions will be set for $PERM"
fi
fi

#BACKUP THEMES DIR
        echo "Backing up THEMES Directory..."
        echo ""
        tar -zcf $wpsite/wp-content/themes.$TIME.tar.gz $wpsite/wp-content/themes
        echo ""
        echo "done."
        echo ""
        echo "temporarily moving $wpsite themes to $wpsite/wp-content/themes.bak1"

        if [ -d $wpsite/wp-content/themes.bak1 ] ; then
        echo "Warning! $wpsite/wp-content/themes.bak1 exists"
        echo "Rotating $wpsite/wp-content/themes.bak1 to plugins.$TIME"
        mv $wpsite/wp-content/themes.bak1 $wpsite/wp-content/themes.$TIME
        echo "Moving $wpsite themes to themes.bak1"
        mv $wpsite/wp-content/themes $wpsite/wp-content/themes.bak1
       echo ""
        mkdir $wpsite/wp-content/themes
        chown $PERM $wpsite/wp-content/themes

else

        echo "Backing up $wpsite themes"
        mv $wpsite/wp-content/themes $wpsite/wp-content/themes.bak1
        mkdir $wpsite/wp-content/themes
        chown $PERM $wpsite/wp-content/themes
fi

        echo "Gathering list of themes"
        #######PULL THEME DIR LIST
##THEME LIST MAKE SURE CUT IS RIGHT
#        ls -d $wpsite/wp-content/plugins.bak1/*/ | cut -f5 -d'/' > themelist

if [ -f $getwp/wp-config.php ] ; then
ls -d $wpsite/wp-content/themes.bak1/*/ | cut -f4 -d'/' > themelist

else

#wpsite1=`find $wpsite -type f -name wp-config.php`
ls -d $wpsite/wp-content/themes.bak1/*/ | cut -f5 -d'/' > themelist

fi


echo "verifying if all Themes are available in wp repo"

# verify which themes available are in wordpress repo. if they arent, remove from list.

if [ -f themelistremoved ] ; then
rm -f themelistremoved
fi
       for pinstall in $(cat themelist) ; do

curl -sL -w "%{http_code} %{url_effective}\\n" "URL" -o /dev/null "https://wordpress.org/themes/$pinstall" -o /dev/null > htcode

catcode=`tail -1 htcode | cut -c1,2,3`


if [ $catcode = "200" ]; then

echo ""
#echo "$catcode $pinstall available in WP repo. Will reinstall without issue"

else

echo "$pinstall not found in WP repo. Removing from list to reinstall"

echo $pinstall >> themelistremoved
sed -i s/$pinstall// themelist
fi
done



        echo "Installing themes.."

       for pinstall in $(cat themelist) ; do

   #########Check if theme download  already exists
   if [ -d $pinstall ]
   then
             echo ""
               rm -rf $pinstall
                 rm -f $pinstall.zip
          fi

wget -q --no-check-certificate https://downloads.wordpress.org/theme/$pinstall.zip | tr -d '\r'

unzip -q $pinstall.zip

mkdir -p $wpsite/wp-content/themes/$pinstall

cp -r $pinstall/* $wpsite/wp-content/themes/$pinstall

#clean up
if [ -f $pinstall.zip ]
then

chown -R $PERM $wpsite/wp-content/themes/$pinstall

echo "$pinstall SUCCESS. Permissions $PERM applied"

rm $pinstall.zip
rm -rf $pinstall
rm -f $pinstall
echo ""

else
        echo "Possible Failure. Please test site; and restore from backup if necessary"

fi

done

coun=`cat themelist | grep -v -e '^$' | wc -l`
echo ""
echo "$coun Themes successfully re-installed. If you have Themes that were not installed due to errors, place them back in Themes directory from the themes.bak1 directory"
rm -f themelist
echo ""
            ;;


############################################################################################################################################################################WORDPRESS BACKUPS #4
########### WORD PRESS BACKUPS############# #4
        "Backup Wordpress")
        ## START - Backup Current Wordpress Directory ##

echo "Please enter Wordpress site to backup (just domain)"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Directory!"
        done

if [ -f $getwp/wp-config.php ] ; then
wpsite=`find $getwp -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

else

wpsite=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1,2`
wpsite2=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

fi
read -p "Wordpress install for $getwp found at $wpsite. Is this correct? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    echo "EXITING..."
    exit 1
  else
    echo
    echo "PROCEEDING.."
  fi

##Tar Directory##

TIME=`date +%b%d%yT%H%M%SZ`
#BASE=`echo "${PWD##*/}"`
#FILENAME=$BASE-$TIME.tar.gz
#SRCDIR=*
#DESDIR=../

echo -n "Would you like to include uploads directory in backup? (y/n) : "
read answercleaning1
if [ $answercleaning1 == "y" -o $answercleaning1 == "Y" -o $answercleaning1 == "yes" -o $answercleaning1 == "YES" ]; then
echo ""

echo "Wordpress backup including uploads directory beginning..."

tar -zcf $wpsite.$TIME.tar.gz $wpsite

SIZE=`du -hs $wpsite.$TIME.tar.gz`

echo "Backup Completed $SIZE"

else
echo ""
echo "Wordpress backup excluding uploads directory beginning..."
sleep 1

tar -zcf $wpsite.$TIME.tar.gz --exclude="$wpsite/wp-content/uploads" $wpsite

SIZE1=`du -hs $wpsite.$TIME.tar.gz`

echo "Backup Completed $SIZE1"

fi
;;

################################################################################################################################################################# UPGRADE WP CORE #5
        "Upgrade to Latest WP Core")
        echo "Upgrading to Latest Wordpress"


echo "Please enter Wordpress site (just domain)"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Directory!"
        done

if [ -f $getwp/wp-config.php ] ; then
wpsite=`find $getwp -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

else

#wpsite1=`find $wpsite -type f -name wp-config.php`
wpsite=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1,2`
wpsite2=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

fi
read -p "Wordpress install for $getwp found at $wpsite. Is this correct? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    echo "EXITING..."
    exit 1

 else
    echo
    echo "PROCEEDING.."
  fi


###PULL WP-VERSION
WPVERS=`cat $wpsite/wp-includes/version.php | grep "wp_version =" | cut -d= -f2 | tr -d \' | tr -d \; | xargs`

echo -n "Are you sure you would like to upgrade $getwp Wordpress $WPVERS? to the latest version(y/n) : "
read answercleaning
if [ $answercleaning == "y" -o $answercleaning == "Y" -o $answercleaning == "yes" -o $answercleaning == "YES" ];
then
echo ""

## END - Question has been asked above ##

## START - Backup Current Wordpress Directory ##


##Tar Directory##

TIME=`date +%b%d%yT%H%M%SZ`

echo -n "Would you like to include uploads directory in backup? (y/n) : "
read cleaning1
if [ $cleaning1 == "y" -o $cleaning1 == "Y" -o $cleaning1 == "yes" -o $cleaning1 == "YES" ]; then
echo ""

echo "Wordpress backup including uploads directory beginning..."

tar -zcf $wpsite.$TIME.tar.gz $wpsite

SIZE=`du -hs $wpsite.$TIME.tar.gz`

echo "Backup Completed $SIZE"

else
echo ""
echo "Wordpress backup excluding uploads directory beginning..."
sleep 1

tar -zcf $wpsite.$TIME.tar.gz --exclude="$wpsite/wp-content/uploads" $wpsite

SIZE1=`du -hs $wpsite.$TIME.tar.gz`

echo "Backup Completed $SIZE1"

fi


## END - Backup Current Wordpress Directory ##


## START - Removing Old Wordpress Download Directory if found from previous cleaning ##

rm -rf wordpress_web 2>/dev/null

## END - Remove old Wordpress Directory if found from previous cleaning ##

## START -  Make Directory and Download ZIP from Wordpress.org ##


echo "####DOWNLOADING Latest Wordpress"####
#DOWNLOAD VERSION

curl --create-dirs -o wordpress_web/wordpress.zip https://wordpress.org/latest.zip
unzip -qd wordpress_web wordpress_web/wordpress.zip

## END - Make Directory and Downloadf ZIP From Wordpress.org ##
echo "done"
## START - Remove Excess files from fresh Wordpress download to avoid overwriting live files ##

rm wordpress_web/wordpress.zip
mv wordpress_web/wordpress/wp-content/themes/index.php tindex.php
mv wordpress_web/wordpress/wp-content/plugins/index.php pindex.php
mv wordpress_web/wordpress/wp-content/index.php windex.php
rm -rf wordpress_web/wordpress/wp-content
rm wordpress_web/wordpress/wp-config-sample.php

## END - Remove Excess files from fresh Wordpress download to   avoid overwriting live files ##

## START - Remove bad directories from hacked site and move wp-config file to avoid being deleted  ##
echo ""
echo "Removing old Wordpress Core Files and Directories..."
rm -rf $wpsite/wp-includes
rm -rf $wpsite/wp-admin
rm $wpsite/wp-content/themes/index.php
rm $wpsite/wp-content/plugins/index.php
echo ""
echo "Backing up wp-config.php"
mv $wpsite/wp-config.php $wpsite/config.php
rm $wpsite/wp-*.php
rm $wpsite/index.php
echo ""
echo "Replacing Wordpress Core Files"
mv wordpress_web/wordpress/* $wpsite/
echo ""
echo "Restoring wp-config.php"
mv $wpsite/config.php $wpsite/wp-config.php
mv tindex.php $wpsite/wp-content/themes/index.php
mv pindex.php $wpsite/wp-content/plugins/index.php
mv windex.php $wpsite/wp-content/index.php
echo ""
echo "done"
## END - Remove bad directories from hacked site and move wp-config file to avoid being deleted ##

echo ""
sleep 1

## START - Change Permission of Wordpress files ##

## START - Verify uploads directory is there and permissions locked down accordingly
if [ ! -d $wpsite/wp-content/uploads ];
then
        mkdir -p $wpsite/wp-content/uploads
fi

## END - Verify uploads directory is there and permissions locked down accordingly

 ## START GET APPROPRIATE USER INFO


                ApacheUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`
                GroupUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`



## START - Change Ownership

echo "Updating Ownership Permissions to $ApacheUser:$GroupUser"
echo  "If you would like to change press 'n' If this is OK, press 'y'"

read own
if [ $own == "y" -o $own == "Y" -o $own == "yes" -o $own == "YES" ]; then

chown -R $ApacheUser:$GroupUser $wpsite

echo "chown successful"

else

echo "Please Enter Apache/System User and Group In the following format User:Group"
echo ""
while read -p 'User:Group:' ans && [[ -z "$ans" ]] ; do
 echo "Please enter User and Group!"
done

echo ""
printf "You've entered $ans is this correct?"
echo ""

read ans1
if [ $ans1 == "y" -o $ans1 == "Y" -o $ans1 == "yes" -o $ans1 == "YES" ]; then

chown -R $ans $wpsite

echo "chown successful"

else

echo "Please RE-Enter Apache/System User and Group In the following format User:Group"

while read -p 'User:Owner:' ans2 && [[ -z "$ans2" ]] ; do

 echo "Please enter User and Group!"
done

chown -R $ans2 $wpsite

echo "chown successful"

fi
fi

## END - Change Ownership

printf "Updating Wordpress Directories Permissions 755\n"
find $wpsite -type d -exec chmod 755 {} \;

sleep 2

printf "Updating Wordpress Files to 644 \n"
find $wpsite -type f -exec chmod 644 {} \;

## END - Complete Permission changes ##
echo ""
echo "Wordpress Directories and Files have been set"
echo ""
sleep 2
printf "======================================\n"
printf "** Wordpress core has been updated **\n"


### Cleaning up temp files ###
rm -rf wordpress_web

printf "===================================\n\n"

printf "===========================================================================\n"
printf "*** Please check the website to make sure it is functioning as expected ***\n"
printf "===========================================================================\n"
else
echo ""
echo "Exiting"
sleep 1
exit
fi
;;

#############################################################################################################################################################################################HARDEN WORDPRESS #6
"Harden Wordpress 6G FW")
            echo "Hardening Wordpress"
echo "Please enter Wordpress site (just domain)"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Directory!"
        done

if [ -f $getwp/wp-config.php ] ; then
wpsite=`find $getwp -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

else

wpsite=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1,2`
wpsite2=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

fi
read -p "Wordpress install for $getwp found at $wpsite. Is this correct? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
   echo "EXITING..."
    exit 1

 else
    echo
    echo "PROCEEDING.."
  fi


        cat > $wpsite/.htaccess <<'EOL'

# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress

# 6G FIREWALL/BLACKLIST
# @ https://perishablepress.com/6g/

# 6G:[QUERY STRINGS]
<IfModule mod_rewrite.c>
        RewriteEngine On
        RewriteCond %{QUERY_STRING} (eval\() [NC,OR]
        RewriteCond %{QUERY_STRING} (127\.0\.0\.1) [NC,OR]
        RewriteCond %{QUERY_STRING} ([a-z0-9]{2000}) [NC,OR]
        RewriteCond %{QUERY_STRING} (javascript:)(.*)(;) [NC,OR]
        RewriteCond %{QUERY_STRING} (base64_encode)(.*)(\() [NC,OR]
        RewriteCond %{QUERY_STRING} (GLOBALS|REQUEST)(=|\[|%) [NC,OR]
        RewriteCond %{QUERY_STRING} (<|%3C)(.*)script(.*)(>|%3) [NC,OR]
        RewriteCond %{QUERY_STRING} (\\|\.\.\.|\.\./|~|`|<|>|\|) [NC,OR]
        RewriteCond %{QUERY_STRING} (boot\.ini|etc/passwd|self/environ) [NC,OR]
        RewriteCond %{QUERY_STRING} (thumbs?(_editor|open)?|tim(thumb)?)\.php [NC,OR]
        RewriteCond %{QUERY_STRING} (\'|\")(.*)(drop|insert|md5|select|union) [NC]
        RewriteRule .* - [F]
</IfModule>

# 6G:[REQUEST METHOD]
<IfModule mod_rewrite.c>
        RewriteCond %{REQUEST_METHOD} ^(connect|debug|delete|move|put|trace|track) [NC]
        RewriteRule .* - [F]
</IfModule>

# 6G:[REFERRERS]
<IfModule mod_rewrite.c>
        RewriteCond %{HTTP_REFERER} ([a-z0-9]{2000}) [NC,OR]
        RewriteCond %{HTTP_REFERER} (semalt.com|todaperfeita) [NC]
        RewriteRule .* - [F]
</IfModule>

# 6G:[REQUEST STRINGS]
<IfModule mod_alias.c>
        RedirectMatch 403 (?i)([a-z0-9]{2000})
        RedirectMatch 403 (?i)(https?|ftp|php):/
        RedirectMatch 403 (?i)(base64_encode)(.*)(\()
        RedirectMatch 403 (?i)(=\\\'|=\\%27|/\\\'/?)\.
        RedirectMatch 403 (?i)/(\$(\&)?|\*|\"|\.|,|&|&amp;?)/?$
        RedirectMatch 403 (?i)(\{0\}|\(/\(|\.\.\.|\+\+\+|\\\"\\\")
        RedirectMatch 403 (?i)(~|`|<|>|:|;|,|%|\\|\s|\{|\}|\[|\]|\|)
        RedirectMatch 403 (?i)/(=|\$&|_mm|cgi-|etc/passwd|muieblack)
        RedirectMatch 403 (?i)(&pws=0|_vti_|\(null\)|\{\$itemURL\}|echo(.*)kae|etc/passwd|eval\(|self/environ)
        RedirectMatch 403 (?i)\.(aspx?|bash|bak?|cfg|cgi|dll|exe|git|hg|ini|jsp|log|mdb|out|sql|svn|swp|tar|rar|rdf)$
        RedirectMatch 403 (?i)/(^$|(wp-)?config|mobiquo|phpinfo|shell|sqlpatch|thumb|thumb_editor|thumbopen|timthumb|webshell)\.php
</IfModule>

# 6G:[USER AGENTS]
<IfModule mod_setenvif.c>
        SetEnvIfNoCase User-Agent ([a-z0-9]{2000}) bad_bot
        SetEnvIfNoCase User-Agent (archive.org|binlar|casper|checkpriv|choppy|clshttp|cmsworld|diavol|dotbot|extract|feedfinder|flicky|g00g1e|harvest|heritrix|httrack|kmccrew|loader|miner|nikto|nutch|planetwork|postrank|purebot|pycurl|python|seekerspider|siclab|skygrid|sqlmap|sucker|turnit|vikspider|winhttp|xxxyy|youda|zmeu|zune) bad_bot
        <limit GET POST PUT>
                Order Allow,Deny
                Allow from All
                Deny from env=bad_bot
        </limit>
</IfModule>

# 6G:[BAD IPS]
<Limit GET HEAD OPTIONS POST PUT>
        Order Allow,Deny
        Allow from All
        # uncomment/edit/repeat next line to block IPs
        # Deny from 123.456.789
</Limit>
EOL

        cat > $wpsite/wp-content/uploads/.htaccess <<'EOL'

# Protect this file

<Files .htaccess>
Order Deny,Allow
Deny from All
</Files>

# whitelist file extensions to prevent executables being
# accessed if they get uploaded
order deny,allow
deny from all

<Files ~ ".(docx?|xlsx?|pptx?|txt|pdf|xml|css|jpe?g|jpg|mp4|mp3|mov|wmv|png|gif)$">
allow from all
</Files>
EOL

echo ""
echo "Applying File and Directory Permissions on $wpsite"
echo ""
echo ""
echo "find $wpsite -type d -exec chmod 755 {} \;"
find $wpsite -type d -exec chmod 755 {} \;
echo ""
echo "find $wpsite -type f -exec chmod 644 {} \;"
find $wpsite -type f -exec chmod 644 {} \;
echo ""
echo ""
printf "** Completed Wordpress Hardening **\n"
printf "===================================\n\n"


;;

########################################################################################################################################################################################FINDBOT SHELL SCAN #7
"Findbot Shell Scan")
            echo "Findbot Shell Scan"
TIME=`date +%m%d%H%M%SZ`
echo "Please Enter Site or Path To Scan.."
echo ""
while read -p 'Directory: ' pans && [[ -z "$pans" ]] ; do
 echo "Please enter Site or Path o scan!"
done

echo "$pans"
rm -f findbot.pl

echo "Downloading findbot.pl from Master"
wget -q https://github.com/chnm/atop/blob/master/findbot.pl
echo ""
echo ""
echo "scanning $pans ... Please wait."
echo ""
perl findbot.pl -c $pans/ > findout$TIME.txt
echo ""
echo "Finished scanning. Results: findout$TIME.txt"


;;
##############################################################################################
################################################## SCAN UPLOADS DIR #9

        "Scan Uploads Dir")
echo "Please enter Wordpress site (just domain)"
        while read -p 'Wordpress site name: ' getwp && [[ -z "$getwp" ]] ; do
                echo "Please enter Directory!"
        done

if [ -f $getwp/wp-config.php ] ; then
wpsite=`find $getwp -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

else

#wpsite1=`find $wpsite -type f -name wp-config.php`
wpsite=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1,2`
wpsite2=`find $getwp -maxdepth 2 -type f -name wp-config.php | grep -v $wpsite/*.bak1 | grep -v $wpsite/*.bak | grep -v $wpsite/*.*Z | cut -d/ -f1`

fi
read -p "Wordpress install for $getwp found at $wpsite. Is this correct? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    echo "EXITING..."
    exit 1
  else
    echo
    echo "PROCEEDING.."
  fi

echo ""
echo "Scanning $wpsite/wp-content/uploads"
echo ""
echo ""

if [ -f upfindweb ] ; then
rm upfindweb
fi

find $wpsite/wp-content/uploads -type f -iname "*.php*" | while read line; do
    echo "Found file '$line'"
    echo "Found file '$line'" >> upfindweb
done

if [ -f upfindweb ] ; then

read -p "Would you like to delete the files found? (y/n) " -n1

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    echo "EXITING..."
  else
    echo
    echo "Deleting..."
    find $wpsite/wp-content/uploads -type f -iname "*.php*" -exec rm -f {} \; | while read line; do
    echo "'$line' Deleted."
done
  echo "COMPLETE"
  fi

else
echo "No Rogue Files Identified. Exiting..."

fi
;;

################################################################################
######################################################## LOCK DOWN SITES
        "Lock/Unlock Sites")


#if [ $# -eq 0 ]
#then
        set -- "."
#fi
#cd /var/www/sites

        ##SET PERMISSIONS
        ## START GET APPROPRIATE USER INFO


                ApacheUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`
                GroupUser=`egrep -iw '^user' /etc/httpd/conf/httpd.conf | awk '{print $2}'`


        ## START - Change Ownership

        echo "Found current apache permissions $ApacheUser:$GroupUser"
        echo  "If you would like to change press 'n' If this is OK, press 'y'"

        read own
        if [ $own == "y" -o $own == "Y" -o $own == "yes" -o $own == "YES" ]; then

PERM=$ApacheUser:$GroupUser
pach=$ApacheUser
roup=$GroupUser

echo "Permissions will be applied for $PERM"
        else

                echo "Please Enter Apache/System User and Group In the following format User:Group"
                echo ""
                while read -p 'User:Group:' ans && [[ -z "$ans" ]] ; do
                         echo "Please enter Userand Group!"
                 done

echo ""
                 printf "You've entered $ans is this correct?"
                 echo ""

                 read ans1
                 if [ $ans1 == "y" -o $ans1 == "Y" -o $ans1 == "yes" -o $ans1 == "YES" ]; then

PERM=$ans
pach=`echo $PERM | awk -F":" '{print $1}'`
roup=`echo $PERM | awk -F":" '{print $2}'`

echo "Permissions will be applied for $PERM"
                 else

                         echo "Please RE-Enter Apache/System User and Group In the following format User:Group"

                         while read -p 'User:Owner:' ans2 && [[ -z "$ans2" ]] ; do

                                  echo "Please enter User and Group!"
                          done

PERM=$ans2
pach=`echo $PERM | awk -F":" '{print $1}'`
roup=`echo $PERM | awk -F":" '{print $2}'`

echo "Permissions will be appliedfor $PERM"
fi
fi

allSites=$(ls -d */ | sed 's/\///g' | grep -e '.com$' -e '.net$' -e '.org$' -e '.biz$' -e '.cc$')
count=$(echo "$allSites" | grep $1 | wc -l)
if [ $count -eq 1 ];
then
        site=$(echo "$allSites" | grep $1 )
else
        if [ $count -ge 2 ];
        then
                echo
                echo "****  Multiple domains found.  ****"
                echo $pach
                siteList=$(echo "$allSites" | grep $1 )
                echo
                j=1
                list=""
                for i in $siteList;
                do
                        isLocked=$(ls -l | grep " $i$" | awk '{ print $3; }' | sed -e 's/'$pach'/Unlocked/g' | sed -e 's/root/Locked  /g')
                  list="${list}\n${isLocked}  ${i}"
                done
                echo -e "$list" | nl -nrn
                echo
                read -r -p "Please pick a number for a site you want to lock/unlock:  " number
                if [ "$number" -ge 1 ] && [ "$number" -le "$count" ];
                then
                        site=$(echo "$siteList" | sed "${number}q;d")
                else
                        echo "error: Invalid number" >&2
                        echo
#                        exit 1
                fi
        else
                echo "$1 is not a valid domain name." >&2
#                exit 1
        fi
fi
echo
isLocked=$(ls -l | grep " $site$" | awk '{ print $3; }')
if [ "$isLocked" = "root" ];
then
        echo "This site is currently LOCKED!"
        echo
        read -r -p "Are you sure you want to UNLOCK $site? (This may take a while.) [y/N] " response
        echo
        case $response in
                [yY][eE][sS]|[yY])
                        chown -R $PERM $site
                        echo "Done!  $site unlocked."
                        echo
                        ;;
                *)
                        echo "$site unchanged."
                        echo
#                        exit 1
                        ;;
        esac
else
        echo "This site is currrently UNLOCKED!"
        echo
        read -r -p "Are you sure you want to LOCK $site? (This may take a while.) [y/N] " response
        echo
        case $response in
                [yY][eE][sS]|[yY])
                        chown -R  root:$roup $site
                        echo "Done!  $site locked."
                        echo
                        ;;
                *)
                        echo "$site unchanged."
                        echo
#                        exit 1
                        ;;
        esac
fi
#exit
;;
        "PHP Header/Base64 Clean")
echo "Scanning current directory... This may take a while!"

## Checking for flag options.
#one_file=0
#path=.
#while test $# -gt 0; do
#        case "$1" in
#                -f|--file)
#                        shift
#                        if test $# -gt 0; then
#                                one_file=1
#                                path=$(echo "${1}")
#                        else
#                                echo "no file specified"
#                                exit 1
#                        fi
#                        shift
#                        ;;
#        esac

## This function identifies line 1 of the file and genetates various statistics that are used in the cleaning process.
function head_stats
{
lineCount=$(cat "${file}" | wc -l)
lcount=$(grep -o $'\r' "${file}" | wc -l)
if [ $lineCount -eq 0 ];
then
        if [ $lcount -gt 0 ];
        then
                isMicrosoft=1
                TheHead=$(awk -F'\r' '{print $1}' "${file}")
                lineCount=$lcount
        fi
else
        isMicrosoft=0
        TheHead=$(head -1 "${file}")
fi
count=$(echo $TheHead | grep -o "<?php" | wc -l)
charactor=$(echo $TheHead | wc -c)
}


## This function backs up and deletes the file
function delete
{
echo "$1: $file" | tee -a $LOG
if [ $isCleaned -eq 0 ];
then
        tar -rf $TAR "${file}"
fi
rm -f "${file}"
isDeleted=1
}


## This function backs up the file and then deletes line 1.  It then replaces line 1 with "<?php".
function clean_head
{
echo "$1: $file" | tee -a $LOG
if [ $isCleaned -eq 0 ];
then
        tar -rf $TAR "${file}"
fi
echo "<?php" > /tmp/scan.tmp
if [ $isMicrosoft -eq 1 ];
then
        sed -i.tmp -e 's/\r/\n/g' "${file}"
        rm -f "${file}".tmp
fi
tail -n +2 "${file}" >> /tmp/scan.tmp
# cat /tmp/scan.tmp > "${file}"
isCleaned=1
}


## This function backs up the file and then deletes line 1.
function delete_head
{
echo "$1: $file" | tee -a $LOG
if [ $isCleaned -eq 0 ];
then
        tar -rf $TAR "${file}"
fi
if [ $isMicrosoft -eq 1 ];
then
        sed -i.tmp -e 's/\r/\n/g' "${file}"
        rm -f "${file}".tmp
fi

"${file}" > /tmp/scan.tmp
cat /tmp/scan.tmp > "${file}"
isCleaned=1
}


## This function looks for many different ways to obfuscate the word "base" in PHP strings.
function theBase
{
if [ ! -z "$1" ];
then
        if echo "$1" | grep -q -e 'bas\\x65' -e 'bas".chr(101).' -e 'ba\\x73e' -e 'ba".chr(115)."e' -e 'b\\x61se' -e 'b".chr(97)."se' -e '\\x62ase' -e '.chr(98)."ase' -e 'ba\\x73\\x65' -e 'ba".chr(115).chr(101).' -e 'ba".chr(115).".\\x65' -e 'ba\\x73".chr(101).' -e 'b\\x61\\x73e' -e 'b".chr(97).chr(115)."e' -e 'b".chr(97)."\\x73e' -e 'b\\x61".chr(115).e' -e '\\x62\\x61se' -e '.chr(98).chr(97)."se' -e '\\x62".chr(97)."se' -e '.chr(98)."\\x61se' -e 'b\\x61s\\x65' -e 'b".chr(97).s".chr(101).' -e 'b".chr(97)."s\\x65' -e 'b\\x61s".chr(101).' -e '\\x62a".chr(115)."e' -e '\\x62a\\x73e' -e '.chr(98)."a".chr(115)."e' -e '.chr(98)."a\\x73e' -e '\\x62as\\x65' -e '.chr(98)."as".chr(101)."' -e '\\x62as".chr(101).' -e '.chr(98)."as\\x65' -e 'b\\x61\\x73\\x65' -e 'b\\x61\\x73".chr(101).' -e 'b\\x61".chr(115)."\\x65' -e 'b\\x61".chr(115).chr(101).' -e 'b".chr(97)."\\x73\\x65' -e 'b".chr(97)."\\x73".chr(101).' -e 'b".chr(97).chr(115)."\\x65' -e 'b".chr(97).chr(115).chr(101).' -e '\\x62a\\x73\\x65' -e '\\x62a\\x73".chr(101).' -e '\\x62a".chr(115)."\\x65' -e '\\x62a".chr(115).chr(101).' -e '.chr(98)."a\\x73\\x65' -e '.chr(98)."a\\x73".chr(101).' -e '.chr(98)."a".chr(115)."\\x65' -e '.chr(98)."a".chr(115).chr(101).' -e '\\x62\\x61s\\x65' -e '\\x62\\x61s".chr(101).' -e '\\x62".chr(97).s\\x65' -e '\\x62".chr(97)."s".chr(101).' -e '.chr(98)."\\x61s\\x65' -e '.chr(98)."\\x61s".chr(101).' -e '.chr(98).chr(97)."s\\x65' -e '.chr(98).chr(97)."s".chr(101).' -e '\\x62\\x61\\x73e' -e '\\x62\\x61".chr(115).e' -e '\\x62".chr(97)."\\x73e' -e '\\x62".chr(97).chr(115)."e' -e '.chr(98)."\\x61\\x73e' -e '.chr(98)."\\x61".chr(115)."e' -e '.chr(98).chr(97)."\\x73e' -e '.chr(98).chr(97).chr(115)."e' -e '\\x62\\x61\\x73\\x65' -e '\\x62\\x61\\x73".chr(101).' -e '\\x62\\x61".chr(115)."\\x65' -e '\\x62".chr(97)."\\x73\\x65' -e '.chr(98)."\\x61\\x73\\x65' -e '\\x62\\x61".chr(115).chr(101).' -e '\\x62".chr(97).chr(115).\\x65' -e '.chr(98).chr(97)."\\x73\\x65' -e '.chr(98)."\\x61\\x73".chr(101).' -e '\\x62".chr(97)."\\x73".chr(101).' -e '.chr(98)."\\x61".chr(115)."\\x65' -e '\\x62".chr(97).chr(115).chr(101).' -e '.chr(98)."\\x61".chr(115).chr(101).' -e '.chr(98).chr(97)."\\x73".chr(101).' -e '.chr(98).chr(97).chr(115)."\\x65' -e '.chr(98).chr(97).chr(115).chr(101).';
        then
                hasBase=1
        else
                if echo "$1" | grep -o -e "'b['.']*a['.']*s['.']*e" -e "d['.']*e['.']*c['.']*o['.']*d['.']*e" -e "'b['.']*a['.']*s['.']*e['.']*6['.']*4['.']*_['.']*d['.']*e['.']*c['.']*o['.']*d['.']*e" | grep -q "'.'";
                then
                        hasBase=1
                else
                        hasBase=0
                fi
        fi
else
        if grep -q -e 'bas\\x65' -e 'bas".chr(101).' -e 'ba\\x73e' -e 'ba".chr(115)."e' -e 'b\\x61se' -e 'b".chr(97)."se' -e '\\x62ase' -e '.chr(98)."ase' -e 'ba\\x73\\x65' -e 'ba".chr(115).chr(101).' -e 'ba".chr(115).".\\x65' -e 'ba\\x73".chr(101).' -e 'b\\x61\\x73e' -e 'b".chr(97).chr(115)."e' -e 'b".chr(97)."\\x73e' -e 'b\\x61".chr(115).e' -e '\\x62\\x61se' -e '.chr(98).chr(97)."se' -e '\\x62".chr(97)."se' -e '.chr(98)."\\x61se' -e 'b\\x61s\\x65' -e 'b".chr(97).s".chr(101).' -e 'b".chr(97)."s\\x65' -e 'b\\x61s".chr(101).' -e '\\x62a".chr(115)."e' -e '\\x62a\\x73e' -e '.chr(98)."a".chr(115)."e' -e '.chr(98)."a\\x73e' -e '\\x62as\\x65' -e '.chr(98)."as".chr(101)."' -e '\\x62as".chr(101).' -e '.chr(98)."as\\x65' -e 'b\\x61\\x73\\x65' -e 'b\\x61\\x73".chr(101).' -e 'b\\x61".chr(115)."\\x65' -e 'b\\x61".chr(115).chr(101).' -e 'b".chr(97)."\\x73\\x65' -e 'b".chr(97)."\\x73".chr(101).' -e 'b".chr(97).chr(115)."\\x65' -e 'b".chr(97).chr(115).chr(101).' -e '\\x62a\\x73\\x65' -e '\\x62a\\x73".chr(101).' -e '\\x62a".chr(115)."\\x65' -e '\\x62a".chr(115).chr(101).' -e '.chr(98)."a\\x73\\x65' -e '.chr(98)."a\\x73".chr(101).' -e '.chr(98)."a".chr(115)."\\x65' -e '.chr(98)."a".chr(115).chr(101).' -e '\\x62\\x61s\\x65' -e '\\x62\\x61s".chr(101).' -e '\\x62".chr(97).s\\x65' -e '\\x62".chr(97)."s".chr(101).' -e '.chr(98)."\\x61s\\x65' -e '.chr(98)."\\x61s".chr(101).' -e '.chr(98).chr(97)."s\\x65' -e '.chr(98).chr(97)."s".chr(101).' -e '\\x62\\x61\\x73e' -e '\\x62\\x61".chr(115).e' -e '\\x62".chr(97)."\\x73e' -e '\\x62".chr(97).chr(115)."e' -e '.chr(98)."\\x61\\x73e' -e '.chr(98)."\\x61".chr(115)."e' -e '.chr(98).chr(97)."\\x73e' -e '.chr(98).chr(97).chr(115)."e' -e '\\x62\\x61\\x73\\x65' -e '\\x62\\x61\\x73".chr(101).' -e '\\x62\\x61".chr(115)."\\x65' -e '\\x62".chr(97)."\\x73\\x65' -e '.chr(98)."\\x61\\x73\\x65' -e '\\x62\\x61".chr(115).chr(101).' -e '\\x62".chr(97).chr(115).\\x65' -e '.chr(98).chr(97)."\\x73\\x65' -e '.chr(98)."\\x61\\x73".chr(101).' -e '\\x62".chr(97)."\\x73".chr(101).' -e '.chr(98)."\\x61".chr(115)."\\x65' -e '\\x62".chr(97).chr(115).chr(101).' -e '.chr(98)."\\x61".chr(115).chr(101).' -e '.chr(98).chr(97)."\\x73".chr(101).' -e '.chr(98).chr(97).chr(115)."\\x65' -e '.chr(98).chr(97).chr(115).chr(101).' "${file}";
        then
                delete "Base64_decode deleted"
        else
                if grep -o -e "'b['.']*a['.']*s['.']*e" -e "d['.']*e['.']*c['.']*o['.']*d['.']*e" -e "'b['.']*a['.']*s['.']*e['.']*6['.']*4['.']*_['.']*d['.']*e['.']*c['.']*o['.']*d['.']*e" "${file}" | grep -q "'.'";
                then
                        delete "Base64_decode deleted"
                fi
        fi
fi
}


## This function gets called if there is more than one instance of "<?php" in line 1.
function more_than_1
{
##  If line 1 is over 4000 charactors long.
if [ "$charactor" -gt 4000 ];
then
        if echo $TheHead | grep -q '^[[:space:]]*<?php';
        then
                clean_head "PHP header cleaned in"
        fi
else
        if echo $TheHead | grep -qe '"\w*b\w*a\w*s\w*e\w*6\w*4\w*_\w*d\w*e\w*c\w*o\w*d\w*e\w*"';
        then
                clean_head "PHP header cleaned in"
        fi
fi
## If the file is longer than 2 lines.  Else, it's ignored for now so it can be deleted in the next phase.
if [ $lineCount -gt 2 ]  && [ $isCleaned -eq 0 ];
then
        if echo $TheHead | grep -e '\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*' | grep -q eval;
        then
            clean_head "Base64_decode injection cleaned in"
        fi
fi
}


## This function gets called if there is exactly one instance of "<?php" in line 1 but it is still suspiciously long.
function exactly_1
{
if echo "$TheHead" | grep -q -e "<?php eval(gzinflate(base64_decode('";
then
        delete_head "Gzinflate injection removed"
fi
if [ $isCleaned -eq 0 ];
then
        theBase $TheHead
        if [ $hasBase -eq 1 ] && [ $lineCount -gt 2 ];
        then
                clean_head "Base64_decode injection cleaned in"
        fi
fi
if [ $isCleaned -eq 0 ];
then
        if echo "$TheHead" | grep -q -e "if (\!function_exists('\w*')){\$GLOBALS\['\w*.'\] = '\^.*{\$\w=\$GLOBALS\['\w*'\].*;?>";
        then
                delete_head "Globals injection cleaned in"
        fi
fi
}


## This function attepmts to clean the file of known injections without deleting it.
function cleaning_pass
{
if [ $count -ge 2 ];
then
        more_than_1
fi
if [ $count -eq 1 ] && [ "$charactor" -gt 1000 ]  && [ $isCleaned -eq 0 ];
then
        exactly_1
fi
## This deletes an injection that commonly infects themes and can cause the site to be blacklisted.
if grep -q "setTimeout(10)" "${file}";
then
        echo "Removed malicious injection from $file" | tee -a $LOG
        if [ $isCleaned -eq 0 ];
        then
                tar -rf $TAR "${file}"
        fi
        sed -i.injected '/setTimeout(10)/d' "${file}"
        rm -f "${file}".injected
fi
if grep -q -e 'error_reporting(0);ini_set("display_errors", 0);include_once(sys_get_temp_dir()."' "${file}";
then
        echo "Removed malicious injection from $file" | tee -a $LOG
        if [ $isCleaned -eq 0 ];
        then
                tar -rf $TAR "${file}"
        fi
        sed -i.injected 's/<?php[[:space:]]*error_reporting(0);ini_set("display_errors", 0);include_once(sys_get_temp_dir()."\/SESS_[0-9,a-f]*"); ?>//g' "${file}"
        rm -f "${file}".injected
        isCleaned=1
fi
if grep -q -e '<?php eval(base64_decode(.\w*[=]*.));?>' "${file}";
then
        echo "Removed base64_decode injection from $file" | tee -a $LOG
        if [ $isCleaned -eq 0 ];
        then
                tar -rf $TAR "${file}"
        fi
        sed -i.injected 's/<?php eval(base64_decode(.*.));?>//g' "${file}"
        rm -f "${file}".injected
        isCleaned=1
fi
if grep -q -e '@$strings(str_rot13(' "${file}";
then
        if grep -q -e '//###==###' "${file}";
        then
                echo "Removed str_rot13 injection from $file" | tee -a $LOG
                if [ $isCleaned -eq 0 ];
                then
                        tar -rf $TAR "${file}"
                fi
                sed -i.injected '/\/\/###==###/,/\/\/###==###/d' "${file}"
                rm -f "${file}".injected
                isCleaned=1
        else
                echo "Removed str_rot13 injection from $file" | tee -a $LOG
                if [ $isCleaned -eq 0 ];
                then
                        tar -rf $TAR "${file}"
                fi
                sed -i.injected 's/@$strings(str_rot13(//g' "${file}"
                rm -f "${file}".injected
                isCleaned=1
        fi
fi
}


##  This function is only caled if the file contains no newline charactors.
function no_liner
{
##  I've seen deleting empty files break some porly coded sites.
#if grep -q -e '^<?php$' "${file}";
#then
#        delete "Empty PHP file deleted"
#fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e '<\?php[[:space:]]*preg_replace("/' -e '"p"\."r"\."e"\."g"\."_"\."r"\."e"\."p"\."l"\."a"\."c"\."e"' "${file}";
        then
                delete "Preg_replace deleted"
        fi
fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e '<script language="php">@eval(\$_POST\[[0-9]*\])</script>' "${file}";
        then
                delete "Backdoor deleted"
        fi
fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e "=';eval(base64_decode(\\$\w*));exit(); ?>" "${file}";
        then
                delete "Backdoor deleted"
        fi
fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e '; unlink(__FILE__);' "${file}";
        then
                delete "Unlink file deleted"
        fi
fi
}


## This finction gets called if the file contains Microsoft newline return carrages.
function contains_microsoft
{
if grep -q -e '\$\w*=$\w*(\$\w*\[\w*\]);\$\w*=$\w*(\$\w*\[\w*\]);' "${file}";
then
        delete "Cookie based exploit deleted"
fi
}



function hijack_check
{
if grep -q  -e 'array (q,w,e,r,t,y,u,i,o,p,a,s,d,f,g,h,j,k,l,z,x,c,v,b,n,m,q,w,e,r,t,y,u,i,o,p,a,s,d,f,g,h,j,k,l,z,x,c,v,b,n,m,"1","2","3","4","5","6","7","8","9","0");' -e '^\$adr1 = "[.]*";' "${file}";
then
        delete "Hijacking content deleted"
fi
if [ $lineCount -le 10 ] && [ $isDeleted -eq 0 ];
then
        if grep -q -e '$. = mt_rand(0,count($target_urls)-1);' -e 'shuffle($urls);' "${file}"
        then
                delete "Hijacking content deleted"
        fi
fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e 'if(!file_exists(\$dir))mkdir(\$dir, 0777, true);' "${file}";
        then
                delete "Hijacking content deleted"
        fi
fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e "^\$default_action =.*F.*i.*l.*e.*s.*M.*a.*n.*;$" "${file}" && grep -q -e "^\$default_charset =.*W.*i.*n.*d.*o.*w.*s.*-.*1.*2.*5.*1.*;$" "${file}";
        then
                delete "Backdoor deleted"
        fi
fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e 'if (!empty(\$_POST)) {extract(\$_POST); \$\w=\$\w(.., \$\w(\$\w("\w", "", \$\w))); \$\w();}' "${file}";
        then
                delete "Fake library deleted"
        fi
fi
}


## This function is called if the file has exactly one newline charactor
function one_liner
{
#line_two=$(tail -n +2 "${file}" | wc -c)
#if [ $line_two -eq 0 ];
#then
#        if grep -q -e '^<?php$' "${file}";
#        then
#                delete "Empty PHP file deleted"
#        fi
#fi
if [ $isDeleted -eq 0 ];
then
        if grep -q -e 'eval("echo base64_encode(.*);");' "${file}";
        then
                delete "Base64_encode deleted"
        fi
fi
}


## This function is called if the file has a GNU copyright claim in the begining of the file
function gnu_check
{
line_7_count=$(sed '7q;d' "${file}" | wc -c)
if [ $line_7_count -gt 700 ];
then
        delete "Fake GNU library deleted"
fi
#if [ $isDeleted -eq 0 ];
#then
#        if [ $lineCount -eq 14 ];
#        then
#                delete "Fake GNU library deleted"
#        fi
#fi
}


## MAIN FUNCTION STARTS HERE ****************************************************************

Date=$(date +%Y-%m-%d_%H:%M:%S)
mkdir /root/cleaning_logs 2> /dev/null
TAR=/root/cleaning_logs/cleaning_$Date.tar
LOG=/root/cleaning_logs/cleaning_$Date.log
touch $TAR
echo -e "Cleaning in $(pwd) at $Date\n" | tee $LOG
echo > /tmp/scan.tmp
find -L . -type f -name '*.[Pp][Hh][Pp]' -print0 | while IFS='.[Pp][Hh][Pp] ' read -r -d '' file
do
        isDeleted=0
        isCleaned=0
        head_stats
        cleaning_pass
        hijack_check
        if [ $lineCount -eq 0 ] && [ $isDeleted -eq 0 ];
        then
                no_liner
        fi
        if [ $lcount -ge 1 ] && [ $isDeleted -eq 0 ];
        then
                contains_microsoft
        fi
        if [ $lineCount -eq 1 ] && [ $isDeleted -eq 0 ];
        then
                one_liner
        fi
        if [ $isDeleted -eq 0 ];
        then
                if head "${file}" | grep -q -e 'GNU General Public License';
                then
                        gnu_check
                fi
        fi
        if [ $isDeleted -eq 0 ];
        then
                theBase
        fi
        if [ $isDeleted -eq 0 ];
        then
        #Removed becasue I don't know if this one is safe.  I think some themes use it.
        # -e '":q;eval(base64_decode("'
        if grep -q -e '="base" . "64_decode";return \$' -e '="base64_decode";return' -e '"\\x62\\141\\163\\x65\\66\\64\\137\\x64\\145\\x63\\157\\x64\\x65"' -e '("?>".gzuncompress(base64_decode(' -e '\\x65\\x76\\x61\\x6C\\x28\\x67\\x7A\\x69\\x6E\\x66\\x6C\\x61\\x74\\x65\\x28\\x62\\x61\\x73\\x65\\x36\\x34\\x5F\\x64\\x65\\x63\\x6F\\x64\\x65\\x28' -e '=gzinflate(base64_decode(\$' -e '<?php $code=base64_decode("' -e 'stripslashes(base64_decode(base64_decode' -e '= "["\."|"\. "]*b["\."|"\. "]*a["\."|"\. "]*s["\."|"\. "]*e["\."|"\. "]*6["\."|"\. "]*4["\."|"\. "]*_["\."|"\. "]*d["\."|"\. "]*e["\."|"\. "]*c["\."|"\. "]*o["\."|"\. "]*d["\."|"\. "]*e["\."|"\. "]*; assert(\$' -e ';@\$\w*(\$\w*(\$\w*(\$\w*(\$\w*))));?>$' -e '$\w*=gzinflate($code($\w*));' -e '<?php @eval(\$_POST\[\w\]' -e 'eval("return eval(\\"\$' -e "eval(gzinflate(base64_decode(rawurldecode('" -e '\$\w*=strrev(str_ireplace("' -e '<?php session_start();  ob_start("ob_gzhandler"); set_time_limit(0);' "${file}";
        then
                delete "Base64_decode deleted"
        else
                if grep -q -e '\$GLOBALS\[\$GLOBALS\[' -e '[[:space:]]*<?php \$GLOBALS\[' -e '\${"\\x47\\x4c\\x4fB\\x41\\x4c\\x53"}' "${file}";
                then
                        delete "PHP globals file deleted"
                else
                        if grep -q -e "@passthru('perl \w*\.\w\{3\}');" "${file}" && grep -q -e "@exec('perl \w*\.\w\{3\}');" "${file}";
                        then
                                delete "Backdoor deleted"
                        else
                                if grep -q "\.chr([0-9]\{1,3\}\^[0-9]\{1,3\})\.chr([0-9]\{1,3\}\^[0-9]\{1,3\})\.chr([0-9]\{1,3\}\^[0-9]\{1,3\})\.chr([0-9]\{1,3\}\^[0-9]\{1,3\})\." "${file}";
                                then
                                        delete "Obfuscated PHP deleted"
                                else
                                        if echo "$TheHead" | grep -q -e "<?php \$......=urldecode" -e '<?error_reporting(0);$host=urldecode';
                                        then
                                                delete "UrlDecode file deleted"
                                        else
                                                if grep -q -e '$headers .= "X-iGspam-global\: Unsure,' -e '\$current = file_get_contents("http:\/\/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/\$\w");' "${file}";
                                                then
                                                        delete "Un-obfuscated mailer deleted"
                                                else
                                                        if grep -q -e 'base64_decode(\$_POST' -e '$arrChar = "012qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM3456789"' "${file}";
                                                        then
                                                                if [ $lineCount -lt 60 ];
                                                                then
                                                                        delete "Backdoor deleted"
                                                                fi
                                                        else
                                                                if grep -q -e '\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*\$\w*\[[0-9]*\][[:space:]]*\.[[:space:]]*' "${file}" | grep -q eval;
                                                                then
                                                                        delete "Base64_decode deleted"
                                                                else
                                                                        if grep -q -e 'move_uploaded_file/\*;\*/(\$_FILES\["filename"\]\["tmp_name"\], \$_FILES\["filename"\]\["name"\]);' -e '/(bing|googlebot|bingbot|google|yahoo)/' -e 'foreach(\$bot_array as \$bot)' "${file}";
                                                                        then
                                                                                delete "Backdoor deleted"
                                                                        else
                                                                                if grep -q -F 'echo $connection->host."|".$connection->username."|".$connection->password."|".$connection->dbname."| $prefix | $key<br/>\n";' "${file}";
                                                                                then
                                                                                        delete "Magento exploit deleted.  CHANGE DB & MAGENTO PASSWORDS!!! "
                                                                                fi
                                                                        fi
                                                                fi
                                                        fi
                                                fi
                                        fi
                                fi
                        fi
                fi
        fi
##  This fi is for the isDeleted check I jammed in there.  This will be removed once I finish reactoring these last few nested if statements.
        fi
done
rm -f /tmp/scan.tmp
echo
echo "Started at $Date."
echo | tee -a $LOG
echo "Finished at $(date +%Y-%m-%d_%H:%M:%S)" | tee -a $LOG
echo
echo "Backups of modified files and logs stored at /root/cleaning_logs/"
##Use for Linux
echo "There is currently $(du -h --max-depth 0 /root/cleaning_logs | awk '{ print $1; }') of space used by the cleaning backups and there is $(df -h | grep -e " /$" | awk '{ print $4; }') remaining on the root filesystem."
##Use for FreeBSD
#echo "There is currently $(du -h -d 0 /root/cleaning_logs | awk '{ print $1; }') of space used by the cleaning backups and there is $(df -h | grep -e " /$" | awk '{ print $4; }') remaining on the root filesystem."
echo
exit 0

;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done

