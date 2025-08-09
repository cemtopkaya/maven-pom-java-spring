#!/usr/bin/env bash

# Argument parser: check for --phase=postCreate or --phase=initialize
phase=""
for arg in "$@"; do
    case "$arg" in
        --phase=postCreate)   phase="postCreate"   ;;
        --phase=postStart)    phase="postStart"    ;;
        --phase=initialize)   phase="initialize"   ;;
    esac
done

if [[ "$phase" == "initialize" ]]; then
    echo "===> initialize aşaması çalışıyor <===="
    # Eğer sahiplik ve izinler doğruysa işlem yapma, değilse düzelt
    dir="./services/jenkins/volume/jenkins_home"
    need_chown=false
    need_chmod=false
    
    # Sahiplik kontrolü
    echo "Sahiplik ve izinler kontrol ediliyor..."
    owner=$(stat -f '%Su' "$dir" 2>/dev/null)
    echo "Sahip: $owner"
    if [[ "$owner" != "$(whoami)" ]]; then
        need_chown=true
    fi
    # İzin kontrolü (en az 755 olmalı)
    echo "İzinler kontrol ediliyor..."
    perms=$(stat -f '%Lp' "$dir" 2>/dev/null)
    echo "İzinler: $perms"
    if [[ "$perms" != 755 ]]; then
        need_chmod=true
    fi
    
    echo "Sahiplik ve izinler kontrolü tamamlandı."
    echo "need_chown: $need_chown, need_chmod: $need_chmod"
    if [[ "$need_chown" == true || "$need_chmod" == true ]]; then
        sudo chown -R "$(whoami)" "$dir" 2>/dev/null || echo "chown yetkiniz yok, atlanıyor."
        chmod -R 755 "$dir" 2>/dev/null || echo "chmod yetkiniz yok, atlanıyor."
    else
        echo "Sahiplik ve izinler zaten doğru, işlem yapılmadı."
    fi

elif [[ "$phase" == "postCreate" ]]; then
    echo "===> postCreateCommand is running <===="
    # Buraya postCreate aşamasında çalıştırılacak satırları ekleyin
    # Örnek:
    # ./installExtensions.sh

elif [[ "$phase" == "postStart" ]]; then
    echo Running postStartCommand...

else
    echo "No recognized phase. Use --phase=postCreate or --phase=initialize"
    exit 1
fi