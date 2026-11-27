-- [Huso] Türkçe çeviri (en.lua'dan)
Locales["tr"] = {
    UI = {
        modal = {
            save = {
                title = "Görünümü kaydet",
                description = "Bu halinle devam edeceksin"
            },
            exit = {
                title = "Düzenlemeden çık",
                description = "Hiçbir değişiklik kaydedilmeyecek"
            },
            accept = "Evet",
            decline = "Hayır"
        },
        ped = {
            title = "Karakter modeli",
            model = "Model"
        },
        headBlend = {
            title = "Kalıtım",
            shape = {
                title = "Yüz",
                firstOption = "Baba",
                secondOption = "Anne",
                mix = "Karışım"
            },
            skin = {
                title = "Ten",
                firstOption = "Baba",
                secondOption = "Anne",
                mix = "Karışım"
            },
            race = {
                title = "Köken",
                shape = "Yüz şekli",
                skin = "Ten",
                mix = "Karışım"
            }
        },
        faceFeatures = {
            title = "Yüz özellikleri",
            nose = {
                title = "Burun",
                width = "Genişlik",
                height = "Yükseklik",
                size = "Boyut",
                boneHeight = "Kemik yüksekliği",
                boneTwist = "Kemik eğimi",
                peakHeight = "Uç yüksekliği"
            },
            eyebrows = {
                title = "Kaşlar",
                height = "Yükseklik",
                depth = "Derinlik"
            },
            cheeks = {
                title = "Yanaklar",
                boneHeight = "Elmacık yüksekliği",
                boneWidth = "Elmacık genişliği",
                width = "Genişlik"
            },
            eyesAndMouth = {
                title = "Gözler ve ağız",
                eyesOpening = "Göz açıklığı",
                lipsThickness = "Dudak kalınlığı"
            },
            jaw = {
                title = "Çene kemiği",
                width = "Genişlik",
                size = "Boyut"
            },
            chin = {
                title = "Çene ucu",
                lowering = "Alçaltma",
                length = "Uzunluk",
                size = "Boyut",
                hole = "Gamze boyutu"
            },
            neck = {
                title = "Boyun",
                thickness = "Kalınlık"
            }
        },
        headOverlays = {
            title = "Görünüm",
            hair = {
                title = "Saç",
                style = "Model",
                color = "Renk",
                highlight = "Röfle",
                texture = "Doku",
                fade = "Geçiş (fade)"
            },
            opacity = "Yoğunluk",
            style = "Model",
            color = "Renk",
            secondColor = "İkinci renk",
            blemishes = "Lekeler",
            beard = "Sakal",
            eyebrows = "Kaşlar",
            ageing = "Yaşlanma",
            makeUp = "Makyaj",
            blush = "Allık",
            complexion = "Cilt tonu",
            sunDamage = "Güneş hasarı",
            lipstick = "Ruj",
            moleAndFreckles = "Ben ve çiller",
            chestHair = "Göğüs kılı",
            bodyBlemishes = "Vücut lekeleri",
            eyeColor = "Göz rengi"
        },
        components = {
            title = "Kıyafetler",
            drawable = "Parça",
            texture = "Doku",
            mask = "Maske",
            upperBody = "Kollar / eller",
            lowerBody = "Pantolon",
            bags = "Çanta ve paraşüt",
            shoes = "Ayakkabı",
            scarfAndChains = "Atkı ve kolye",
            shirt = "İç giyim",
            bodyArmor = "Yelek / zırh",
            decals = "Arma",
            jackets = "Üst / ceket",
            head = "Kafa"
        },
        props = {
            title = "Aksesuarlar",
            drawable = "Parça",
            texture = "Doku",
            hats = "Şapka ve kask",
            glasses = "Gözlük",
            ear = "Kulak",
            watches = "Saat",
            bracelets = "Bileklik"
        },
        tattoos = {
            title = "Dövmeler",
            items = {
                ZONE_TORSO = "Gövde",
                ZONE_HEAD = "Kafa",
                ZONE_LEFT_ARM = "Sol kol",
                ZONE_RIGHT_ARM = "Sağ kol",
                ZONE_LEFT_LEG = "Sol bacak",
                ZONE_RIGHT_LEG = "Sağ bacak"
            },
            apply = "Uygula",
            delete = "Kaldır",
            deleteAll = "Tüm dövmeleri kaldır",
            opacity = "Yoğunluk"
        }
    },
    outfitManagement = {
        title = "Kombin yönetimi",
        jobText = "Meslek kombinlerini yönet",
        gangText = "Çete kombinlerini yönet"
    },
    cancelled = {
        title = "Düzenleme iptal edildi",
        description = "Görünüm kaydedilmedi"
    },
    outfits = {
        import = {
            title = "Kombin kodunu gir",
            menuTitle = "Kombin içe aktar",
            description = "Paylaşım koduyla kombin ekle",
            name = {
                label = "Kombine isim ver",
                placeholder = "Güzel bir kombin",
                default = "İçe aktarılan kombin"
            },
            code = {
                label = "Kombin kodu"
            },
            success = {
                title = "Kombin eklendi",
                description = "Kombin menüsünden bu kombini giyebilirsin"
            },
            failure = {
                title = "İçe aktarma başarısız",
                description = "Geçersiz kombin kodu"
            }
        },
        generate = {
            title = "Kombin kodu oluştur",
            description = "Paylaşmak için kombin kodu oluştur",
            failure = {
                title = "Bir şeyler ters gitti",
                description = "Bu kombin için kod oluşturulamadı"
            },
            success = {
                title = "Kombin kodu oluşturuldu",
                description = "Kombin kodun"
            }
        },
        save = {
            menuTitle = "Üstümdekini kaydet",
            menuDescription = "Üstündekini %s kombini olarak kaydet",
            description = "Şu anki kıyafetini kombin olarak kaydet",
            title = "Kombine isim ver",
            managementTitle = "Yönetim kombini bilgileri",
            name = {
                label = "Kombin adı",
                placeholder = "Çok havalı bir kombin"
            },
            gender = {
                label = "Cinsiyet",
                male = "Erkek",
                female = "Kadın"
            },
            rank = {
                label = "En düşük rütbe"
            },
            failure = {
                title = "Kaydedilemedi",
                description = "Bu isimde bir kombin zaten var"
            },
            success = {
                title = "Başarılı",
                description = "%s kombini kaydedildi"
            }
        },
        update = {
            title = "Kombini güncelle",
            description = "Üstündekini kayıtlı bir kombinin üzerine kaydet",
            failure = {
                title = "Güncellenemedi",
                description = "Böyle bir kombin yok"
            },
            success = {
                title = "Başarılı",
                description = "%s kombini güncellendi"
            }
        },
        change = {
            title = "Kombin değiştir",
            description = "Kayıtlı %s kombinlerinden birini seç",
            pDescription = "Kayıtlı kombinlerinden birini seç",
            failure = {
                title = "Bir şeyler ters gitti",
                description = "Giymeye çalıştığın kombinin temel görünümü yok",
            }
        },
        delete = {
            title = "Kombin sil",
            description = "Kayıtlı bir %s kombinini sil",
            mDescription = "Kayıtlı kombinlerinden birini sil",
            item = {
                title = '"%s" kombinini sil',
                description = "Model: %s%s"
            },
            success = {
                title = "Başarılı",
                description = "Kombin silindi"
            }
        },
        manage = {
            title = "👔 | %s kombinlerini yönet"
        }
    },
    jobOutfits = {
        title = "İş kıyafetleri",
        description = "İş kıyafetlerinden birini seç"
    },
    menu = {
        returnTitle = "Geri",
        title = "Soyunma odası",
        outfitsTitle = "Oyuncu kombinleri",
        clothingShopTitle = "Kıyafet mağazası",
        barberShopTitle = "Berber",
        tattooShopTitle = "Dövme salonu",
        surgeonShopTitle = "Estetik cerrah"
    },
    clothing = {
        title = "Kıyafet al - $%d",
        titleNoPrice = "Kıyafet değiştir",
        options = {
            title = "👔 | Kıyafet mağazası",
            description = "Geniş kıyafet seçeneklerinden seç"
        },
        outfits = {
            title = "👔 | Kombin seçenekleri",
            civilian = {
                title = "Sivil kıyafet",
                description = "Kendi kıyafetlerini giy"
            }
        }
    },
    commands = {
        reloadskin = {
            title = "Karakter görünümünü yeniden yükler",
            failure = {
                title = "Hata",
                description = "Şu anda reloadskin kullanamazsın"
            }
        },
        clearstuckprops = {
            title = "Karaktere takılı kalan bütün eşyaları kaldırır",
            failure = {
                title = "Hata",
                description = "Şu anda clearstuckprops kullanamazsın"
            }
        },
        pedmenu = {
            title = "Kıyafet menüsünü aç / ver",
            failure = {
                title = "Hata",
                description = "Oyuncu çevrim içi değil"
            }
        },
        joboutfits = {
            title = "Meslek kıyafetleri menüsünü açar"
        },
        gangoutfits = {
            title = "Çete kıyafetleri menüsünü açar"
        },
        bossmanagedoutfits = {
            title = "Patronun belirlediği kombinler menüsünü açar"
        }
    },
    textUI = {
        clothing = "Kıyafet mağazası - Fiyat: $%d",
        barber = "Berber - Fiyat: $%d",
        tattoo = "Dövme salonu - Fiyat: $%d",
        surgeon = "Estetik cerrah - Fiyat: $%d",
        clothingRoom = "Soyunma odası",
        playerOutfitRoom = "Kombinler"
    },
    migrate = {
        success = {
            title = "Başarılı",
            description = "Aktarım tamamlandı. %s görünüm aktarıldı",
            descriptionSingle = "Görünüm aktarıldı"
        },
        skip = {
            title = "Bilgi",
            description = "Görünüm atlandı"
        },
        typeError = {
            title = "Hata",
            description = "Geçersiz tür"
        }
    },
    purchase = {
        tattoo = {
            success = {
                title = "Başarılı",
                description = "%s dövmesini %s$ karşılığında yaptırdın"
            },
            failure = {
                title = "Dövme yapılamadı",
                description = "Yeterli paran yok!"
            }
        },
        store = {
            success = {
                title = "Başarılı",
                description = "%s$ ödendi: %s"
            },
            failure = {
                title = "Hile denemesi!",
                description = "Yeterli paran yokken sistemi kandırmaya çalıştın!"
            }
        }
    }
}
