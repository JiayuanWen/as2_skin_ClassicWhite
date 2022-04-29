--Options
competitiveCamera = false --Set this to true to tweak camera angle for competitive play.
oneColorCliff = false --If this is set to true, the track's cliff will be the same color from begin to end. If set to false, the track's cliff will be in rainbow color. 
--End of options

--Extra Graphic Options
showEntireRoad = false --If set to true, the entire track is visible. If set to false, the track is loaded section by section during gameplay.
showRing = true --Toggle ring visibility On/Off.
showBackgroundBuilding = true --Toggle background objects On/Off.
showSkyWire = true --Toggle wires in the sky On/Off.
--End of graphic options

--Make sure to save before heading back to the game.


--------------------------------------------------------------------------------------------------------------------------Skin source code------------------------------------------------------------------------------------------------------------------
do --Lua fif shortcut
    function fif(test, if_true, if_false)
        if test then
            return if_true
        else
            return if_false
        end
    end
end --End of fif setup

do --Graphic quality variables
    hifi = GetQualityLevel() > 2
    function ifhifi(if_true, if_false)
        if hifi then
            return if_true
        else
            return if_false
        end
    end
    quality = GetQualityLevel4()
end --End of graphic quality variables section

do --Frequent used variables setup
    wakeboard = PlayerCanJump()
    skinvars = GetSkinProperties()
    trackWidth = skinvars["trackwidth"] --trackWidth = fif(wakeboard, 11.5, 7)
    ispuzzle = skinvars.colorcount > 1
    fullsteep = wakeboard or skinvars.prefersteep or (not ispuzzle)
    track = GetTrack() --get the track data from the game engine
    song = GetSongCompletionPercentage()

    do --Rail rendering fix
        --source: https://as2-doc.deathbynukes.com/shaders.html

        ------------------------------------------------------------------------------------------------
        -- START of rail fix for fast mods.
        -- (Put this somewhere between "track = GetTrack()" and your first use of CreateRail.)
        -- (By DeathByNukes, for anyone to use.)
        ------------------------------------------------------------------------------------------------
        local min_node_interval, max_node_interval = math.huge, -math.huge
        do
            local last_seconds = track[1].seconds
            for i = 2, #track do
                local seconds = track[i].seconds
                local interval = seconds - last_seconds
                if interval < min_node_interval then
                    min_node_interval = interval
                end
                if interval > max_node_interval then
                    max_node_interval = interval
                end
                last_seconds = seconds
            end
        end
    --[[
	AS2 ignores fullfuture=true if the rail would have over 63500 vertices. (Which is a good idea. Even if it didn't, this function would be good practice.)
	This function generates a value for CreateRail{stretch} which causes fullfuture to always work.
	crossSectionShape_count should be the number of points in crossSectionShape. (e.g. crossSectionShape={{0,0},{1,1}} has 2 points.)
	stretch=X tells it to only create a vertex every X nodes. Effectively, we degrade the rail's quality in response to the song's length.
	It may be useful to multiply the result by some GetQualityLevel()-dependent number. Especially if you're using more than one fullfuture rail.
	To Dylan: It'd be nice if there was a way to have the quality increase for sections of the track close to the player.
	]]
        function fullfutureStretch(crossSectionShape_count)
            return math.ceil(#track * crossSectionShape_count / 63500)
        end

        local auto_stretch
        do
            local required_interval = 0.007 -- ninja is 0.0077, ultimate true ninja is 0.0033
            if min_node_interval < required_interval then
                -- Find a stretch value that causes the spacing between vertices to represent a time of at least required_interval.
                -- todo: There is probably a mathematical formula to calculate this properly in one step.
                auto_stretch = 1
                local effective_interval
                repeat
                    auto_stretch = auto_stretch + 1
                    effective_interval = auto_stretch * min_node_interval
                until effective_interval >= required_interval
            end
        end

        -- Hook the CreateRail function and automatically stretch all rails that use the default stretch setting.
        local original_CreateRail = CreateRail
        function CreateRail(t)
            if t.stretch == nil then
                if not t.fullfuture then
                    t.stretch = auto_stretch
                else
                    local ff_stretch = fullfutureStretch(#t.crossSectionShape)
                    if ff_stretch > 1 then
                        -- In this situation fullfuture would actually be ignored by AS2.
                        t.fullfuture = false
                        t.stretch = auto_stretch
                    end
                end
            end
            return original_CreateRail(t)
        end
        ------------------------------------------------------------------------------------------------
        -- END of rail fix for fast mods.
        ------------------------------------------------------------------------------------------------
    end --end of rail rendering fix
	
end --End of frequent used variables section

do --Skin general settings setup
    quality = GetQualityLevel4()

    if quality < 3 then
        debrisTexture = "textures/scene/FireworkMed.png"
        airdebrisCount = 400
        airdebrisDensity = 50
        blurBool = 0
    elseif quality < 4 then
        debrisTexture = "textures/scene/FireworkHigh.png"
        airdebrisCount = 450
        airdebrisDensity = 50
        blurBool = 0
    else
        debrisTexture = "textures/scene/FireworkUltra.png"
        airdebrisCount = 500
        airdebrisDensity = 50
        blurBool = 1.3
    end

    if quality < 2 then
        introCameraBool = false
    else
        introCameraBool = true
    end

    SetScene {
        glowpasses = 0,
        glowspread = 0,
        radialblur_strength = blurBool,
        watertype = 1,
        water = wakeboard, --only use the water cubes in wakeboard mode
        watertint = {_Color = {colorsource = "highway"}, a = 234},
        watertexture = "textures/scene/Water.png",
        dynamicFOV = false,
        use_intro_swoop_cam = introCameraBool,
        hide_default_background_verticals = true,
        towropes = wakeboard,
        airdebris_count = airdebrisCount,
        airdebris_density = airdebrisDensity,
        airdebris_texture = debrisTexture,
        airdebris_particlesize = 3.9,
        airdebris_shader = "VertexColorUnlitTintedAlpha2",
        airdebris_flashsizescaler = 0.9,
        airdebris_layer = 13,
        useblackgrid = true,
        minimap_colormode = "black",
        twistmode = {curvescaler = 1, steepscaler = fif(fullsteep, 1, .65)}
    }
end --End of skin setting section

do --Post-processing effect(s)
    if quality >= 4 then
        AddPostEffect {
            depth = "background",
            material = radialBlurEffect
        }
    end
end --End of Post-processing effect section

do --Sound effects
    if not ispuzzle then
        LoadSounds {
            hit = "sounds/color.wav",
            hitgrey = "sounds/grey.wav",
            hitgreypro = "sounds/grey.wav",
            matchsmall = "sounds/matchmedium.wav"
        }
    end
end --End of sound section

do -- Block behavior
    if quality < 2 then
        blockCount = 35
    elseif quality < 3 then
        blockCount = 50
    elseif quality < 4 then
        blockCount = 75
    else
        blockCount = 100
    end

    if not wakeboard then
        SetBlocks {
            maxvisiblecount = blockCount,
            colorblocks = {
                mesh = "models/blocks/colorblock.obj",
                shader = "IlluminDiffuse",
                shadercolors = {
                    _Color = {colorsource = "highway"}
                },
                texture = "textures/blocks/Color block.jpg",
                height = 0,
                float_on_water = false,
                scale = {1, 1, 1},
                layer = 14
            },
            greyblocks = {
                mesh = "models/blocks/grey.obj",
                shader = "Reflective/VertexLit",
                texture = "textures/blocks/spike.png",
                layer = 14
            },
            powerups = {
                powerpellet = {
                    mesh = "models/blocks/big.obj",
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = {colorMode = "highwayinverted"},
                        texture = "textures/scene/White.png",
                        height = 0,
                        float_on_water = false,
                        scale = {1, 1, 1}
                    }
                },
                whiteblock = {
                    mesh = "models/blocks/colorblock.obj",
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = {0, 0, 0},
                        texture = "textures/blocks/black.png",
                        height = 0,
                        float_on_water = false,
                        scale = {1, 1, 1}
                    }
                },
                ghost = {
                    mesh = "models/blocks/colorblock.obj",
                    shader = fif(ispuzzle, "Diffuse", "RimLight"),
                    texture = "textures/blocks/Color block.jpg",
                    height = 0,
                    float_on_water = false,
                    scale = {1, 1, 1}
                },
                x2 = {
                    mesh = "models/blocks/x.obj",
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = {0, 0, 0},
                        texture = "textures/blocks/black.png",
                        height = 0,
                        float_on_water = false,
                        scale = {1, 1, 1}
                    }
                },
                x3 = {
                    mesh = "models/blocks/x.obj",
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = {0, 0, 0},
                        texture = "textures/blocks/black.png",
                        height = 0,
                        float_on_water = false,
                        scale = {1, 1, 1}
                    }
                },
                x4 = {
                    mesh = "models/blocks/x.obj",
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = {0, 0, 0},
                        texture = "textures/blocks/black.png",
                        height = 0,
                        float_on_water = false,
                        scale = {1, 1, 1}
                    }
                },
                x5 = {
                    mesh = "models/blocks/x.obj",
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = {0, 0, 0},
                        texture = "textures/blocks/black.png",
                        height = 0,
                        float_on_water = false,
                        scale = {1, 1, 1}
                    }
                }
            }
        }
    end
end --End of mono mode block behavior

do -- Gameplay graphics
    if ispuzzle then
        SetBlocks {
            maxvisiblecount = 35,
            colorblocks = {
                mesh = "models/blocks/colorblock.obj",
                shader = "IlluminDiffuse",
                texture = "textures/blocks/Color block.jpg",
                height = 0,
                float_on_water = false,
                scale = {1, 1, 1}
            }
        }
    end

    if quality < 2 then
        hitTexture = "textures/gameplay/hit2Low.png"
    elseif quality < 3 then
        hitTexture = "textures/gameplay/hit2Med.png"
    elseif quality < 4 then
        hitTexture = "textures/gameplay/hit2High.png"
    else
        hitTexture = "textures/gameplay/hit2Ultra.png"
    end

    SetBlockFlashes {
        texture = hitTexture
    }

    if quality < 2 then
        SetBlockFlashes {
            sizescaler = 0,
            sizescaler_missed = 0
        }
    elseif quality >= 2 then
        SetBlockFlashes {
            sizescaler = 0.6,
            sizescaler_missed = 0.4
        }
    end

    if quality < 2 then
        SetPuzzleGraphics {
            usesublayerclone = false,
            puzzlematchmaterial = {
                shader = "Unlit/Transparent",
                texture = "textures/gameplay/tileMatchingBarsinvert_Low.png",
                shadercolors = "highway",
                aniso = 9,
                layer = 14
            },
            puzzleflyupmaterial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/flyup_Low.png",
                shadercolors = "highway",
                layer = 14
            },
            puzzlematerial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/tilesSquareinvert_Low.png",
                texturewrap = "clamp",
                aniso = 9,
                usemipmaps = "false",
                shadercolors = {0, 0, 0},
                layer = 14
            }
        }
    elseif quality < 3 then
        SetPuzzleGraphics {
            usesublayerclone = false,
            puzzlematchmaterial = {
                shader = "Unlit/Transparent",
                texture = "textures/gameplay/tileMatchingBarsinvert_Med.png",
                shadercolors = "highway",
                aniso = 9,
                layer = 14
            },
            puzzleflyupmaterial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/flyup_Med.png",
                shadercolors = "highway",
                layer = 14
            },
            puzzlematerial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/tilesSquareinvert_Med.png",
                texturewrap = "clamp",
                aniso = 9,
                usemipmaps = "false",
                shadercolors = {0, 0, 0},
                layer = 14
            }
        }
    elseif quality < 4 then
        SetPuzzleGraphics {
            usesublayerclone = false,
            puzzlematchmaterial = {
                shader = "Unlit/Transparent",
                texture = "textures/gameplay/tileMatchingBarsinvert_High.png",
                shadercolors = "highway",
                aniso = 9,
                layer = 14
            },
            puzzleflyupmaterial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/flyup_High.png",
                shadercolors = "highway",
                layer = 14
            },
            puzzlematerial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/tilesSquareinvert_High.png",
                texturewrap = "clamp",
                aniso = 9,
                usemipmaps = "false",
                shadercolors = {0, 0, 0},
                layer = 14
            }
        }
    else
        SetPuzzleGraphics {
            usesublayerclone = false,
            puzzlematchmaterial = {
                shader = "Unlit/Transparent",
                texture = "textures/gameplay/tileMatchingBarsinvert_Ultra.png",
                shadercolors = "highway",
                aniso = 9,
                layer = 14
            },
            puzzleflyupmaterial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/flyup_Ultra.png",
                shadercolors = "highway",
                layer = 14
            },
            puzzlematerial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = "textures/gameplay/tilesSquareinvert_Ultra.png",
                texturewrap = "clamp",
                aniso = 9,
                usemipmaps = "false",
                shadercolors = {0, 0, 0},
                layer = 14
            }
        }
    end

    if skinvars.colorcount < 5 then
        SetBlockColors {
            {r = 0, g = 176, b = 255},
            {r = 0, g = 184, b = 0},
            {r = 255, g = 255, b = 0},
            {r = 255, g = 0, b = 0}
        }
    else
        SetBlockColors {
            {r = 214, g = 0, b = 254},
            {r = 0, g = 176, b = 255},
            {r = 0, g = 240, b = 0},
            {r = 255, g = 255, b = 0},
            {r = 255, g = 0, b = 0}
        }
    end

    SetVideoScreenTransform {
        pos = {120, -99.44, 0},
        rot = {0, 0, 0},
        scale = {10, 6, 3}
    }
end --End of gameplay graphic section

do --Player model
    monoTexture = "textures/player/Mono.png"
    monoColor = "textures/player/MonoColor.png"

    shipMesh =
        BuildMesh {
        mesh = "models/player/ninjamono.obj",
        barycentricTangents = true,
        calculateNormals = false,
        submeshesWhenCombining = false
    }

    shipMaterial =
        BuildMaterial {
        renderqueue = 2000,
        shader = "UnlitTintedTexGlow",
        shadersettings = {_GlowScaler = 9, _Brightness = 0},
        shadercolors = {
            _Color = {128.3, 128.3, 128.3},
            _GlowColor = {colorsource = "highway", scaletype = "intensity", minscaler = 0.155, maxscaler = 0.155}
        },
        textures = {_Glow = monoColor, _MainTex = monoTexture}
    }

    if not ispuzzle then
        ship = {
            min_hover_height = 0.15,
            max_hover_height = 0.9,
            use_water_rooster = false,
            smooth_tilting = false,
            smooth_tilting_speed = 10,
            smooth_tilting_max_offset = -20,
            pos = {x = 0, y = 0, z = 0.20},
            mesh = shipMesh,
            shadowreceiver = true,
            layer = 13,
            reflect = true,
            material = shipMaterial,
            scale = {x = 1, y = 1, z = 1},
            thrusters = {
                crossSectionShape = {
                    {-.35, -.35, 0},
                    {-.5, 0, 0},
                    {-.35, .35, 0},
                    {0, .5, 0},
                    {.35, .35, 0},
                    {.5, 0, 0},
                    {.35, -.35, 0}
                },
                perShapeNodeColorScalers = {1, 1, 1, 1, 1, 1, 1},
                shader = "VertexColorUnlitTinted",
                layer = 13,
                renderqueue = 3999,
                colorscaler = 1.5,
                extrusions = 20,
                stretch = -0.108,
                updateseconds = 0.025,
                instances = {
                    {pos = {0, .49, -1.1}, rot = {0, 0, 0}, scale = {.20, .21, .52}},
                    {pos = {.22, 0.245, -1.1}, rot = {0, 0, 58.713}, scale = {.20, .21, .52}},
                    {pos = {-.22, 0.245, -1.1}, rot = {0, 0, 313.7366}, scale = {.20, .21, .52}}
                }
            }
        }
    end

    if ispuzzle then
        ship = {
            min_hover_height = 0.23,
            max_hover_height = 0.8,
            use_water_rooster = false,
            smooth_tilting = true,
            smooth_tilting_speed = 10,
            smooth_tilting_max_offset = -20,
            pos = {x = 0, y = 0, z = 0},
            mesh = "models/player/vehicle1a.obj",
            shader = "UnlitTintedTexGlow",
            layer = 13,
            reflect = true,
            renderqueue = 2000,
            shadersettings = {_GlowScaler = 9, _Brightness = 0},
            shadercolors = {
                _Color = {128.3, 128.3, 128.3},
                _GlowColor = {colorsource = "highway", scaletype = "intensity", minscaler = 0.155, maxscaler = 0.155}
            },
            textures = {_Glow = "textures/player/vehicle1a_ao_glow.png", _MainTex = "textures/player/vehicle1a_ao.png"},
            scale = {x = 1, y = 1, z = 1},
            thrusters = {
                crossSectionShape = {
                    {-.35, -.35, 0},
                    {-.5, 0, 0},
                    {-.35, .35, 0},
                    {0, .5, 0},
                    {.35, .35, 0},
                    {.5, 0, 0},
                    {.35, -.35, 0}
                },
                perShapeNodeColorScalers = {1, 1, 1, 1, 1, 1, 1},
                shader = "VertexColorUnlitTinted",
                layer = 13,
                renderqueue = 3999,
                colorscaler = 1.5,
                extrusions = 20,
                stretch = -0.108,
                updateseconds = 0.025,
                instances = {
                    {pos = {.549, 0.15, -0.63}, rot = {0, 0, 58.713}, scale = {.20, .21, .573}},
                    {pos = {-.549, 0.15, -0.63}, rot = {0, 0, 313.7366}, scale = {.20, .21, .573}}
                }
            }
        }
    end

    if wakeboard and not ispuzzle then
        SetPlayer {
            cameramode = "first_jumpthird",
            camfirst = {
                pos = {0, 2.7, -3.5},
                rot = {20.5, 0, 0},
                strafefactor = 1
            },
            camthird = {
                pos = {0, 4.3, -4.2},
                rot = {30, 0, 0},
                strafefactor = 0.89
            },
            surfer = {
                arms = {
                    shader = "RimLightHatchedSurfer",
                    shadercolors = {
                        _Color = {
                            colorsource = "highway",
                            scaletype = "intensity",
                            minscaler = 3,
                            maxscaler = 6,
                            param = "_Threshold",
                            paramMin = 2,
                            paramMax = 2
                        },
                        _RimColor = {0, 63, 192}
                    },
                    texture = "textures/wakeboard/FullLeftArm_1024_wAO.png"
                },
                board = {
                    shader = ifhifi("RimLightHatchedSurferExternal", "VertexColorUnlitTintedAlpha"), 
                    renderqueue = 3999,
                    shadercolors = {
                        _Color = {{161, 161, 161}, scaletype = "intensity", minscaler = 5, maxscaler = 5},
                        _RimColor = {205, 205, 205}
                    },
                    shadersettings = {
                        _Threshold = 11
                    },
                    texture = "textures/wakeboard/board_internalOutline.png"
                },
                body = {
                    shader = "RimLightHatchedSurfer", 
                    renderqueue = 3000,
                    shadercolors = {
                        _Color = {255, 255, 255},
                        _RimColor = {0, 0, 0}
                    },
                    shadersettings = {
                        _Threshold = 1.7
                    },
                    texture = "textures/wakeboard/robot_HighContrast.png"
                }
            }
        }
    else
        if competitiveCamera then
            SetPlayer {
                cameramode = "third",
                camfirst = {
                    pos = {0, 1.84, -0.4},
                    rot = {20, 0, 0}
                },
                camthird = {
                    pos = {0, 8, -5},
                    rot = {30, 0, 0},
                    pos2 = {0, 7, -6},
                    rot2 = {30, 0, 0},
                    strafefactorFar = 1,
                    transitionspeed = 1,
                    puzzleoffset = -0.65,
                    puzzleoffset2 = -1.5
                },
                vehicle = ship
            }
        else
            SetPlayer {
                cameramode = "third",
                camfirst = {
                    pos = {0, 1.84, -0.4},
                    rot = {20, 0, 0}
                },
                camthird = {
                    pos = {0, 3.65, -2}, --[0 2 -0.5]
                    rot = {25, 0, 0}, --[30 0 0]
                    strafefactor = 0.85,
                    strafefactorFar = 0.85, --[.75]
                    pos2 = {0, 2.7, -1.55}, --[0 5 -4]
                    rot2 = {25, 0, 0}, --[30 0 0]
                    puzzleoffset = -1,
                    puzzleoffset2 = -1,
                    transitionspeed = 1
                },
                vehicle = ship
            }
        end
    end
end --End of player model behavior section

do --Skybox
    SetSkybox {
        skysphere = "textures/scene/White.png"
    }

    if quality < 2 then
        skywireLayer = 13 -- In Low setting, the background (layer 18) is disabled, so move the skywire to the main layer (13) to remain visible
    else
        skywireLayer = 18
    end

    if showSkyWire then
        skywireMat =
            BuildMaterial {
            renderqueue = 1000,
            --shader = "VertexColorUnlitTinted",
            shader = "UnlitTintedTex",
            colorMode = "static",
            shadercolors = {
                --_Color={r=0,g=0,b=0}
                _Color = {r = 133, g = 133, b = 133}
            },
            texture = "textures/scene/White.png"
        }
         --
        --[[
function Update(dt, trackLocation, playerStrafe, playerJumpHeight, intensity) --Skywire blinks with the music's intensity 
	if skywireMat then
		local greyScale = 255 - (92*intensity)
		UpdateShaderSettings{
			material = skywireMat,
			shadercolors={
				_Color={r=greyScale,g=greyScale,b=greyScale}
			}
		}
	end
end
]] CreateObject {
            --skywires, the lines in the sky. A railed object is attached to the track and moves along it with the player.
            railoffset = 0,
            floatonwaterwaves = false,
            gameobject = {
                name = "scriptSkyWires",
                pos = {x = 0, y = 0, z = 0},
                mesh = "models/sky/skywires.obj",
                material = skywireMat,
                layer = skywireLayer,
                scale = {x = 1, y = 1, z = 1},
                lookat = "end"
            }
        }
    end --endif showSkyWire
end --End of skybox section

do --Track colors
    SetTrackColors {
        --enter any number of colors here. The track will use the first ones on less intense sections and interpolate all the way to the last one on the most intense sections of the track
        {r = 148, g = 10, b = 253},
        {r = 0, g = 177, b = 252},
        {r = 0, g = 168, b = 0},
        {r = 255, g = 255, b = 0},
        {r = 252, g = 0, b = 0}
    }
end --End of track color section

do --Rings
    if quality < 2 then
        ringTexture = "textures/ring/Classic420p.png"
    elseif quality < 3 then
        ringTexture = "textures/ring/Classic720p.png"
    elseif quality < 4 then
        ringTexture = "textures/ring/Classic1080p.png"
    else
        ringTexture = "textures/ring/Classic2160p.png"
    end

    if competitiveCamera then
        ringSizeMultiplier = 2.5
    else
        ringSizeMultiplier = 2
    end

    if not wakeboard then
        if showRing then
            SetRings {
                texture = ringTexture,
                shader = "VertexColorUnlitTintedAlpha2",
                layer = 13, -- on layer13, these objects won't be part of the glow effect
                size = trackWidth * ringSizeMultiplier,
                renderqueue = 2002,
                percentringed = .15,
                airtexture = "textures/wakeboard/Bits.png",
                airshader = "VertexColorUnlitTintedAlpha",
                airsize = 16,
                fullfuture = showEntireRoad
            }
        end
    end

    if wakeboard then
        if showRing then
            SetRings {
                --setup the tracks tunnel rings. the airtexture is the tunnel used when you're up in a jump
                texture = ringTexture,
                shader = "VertexColorUnlitTintedAlpha2",
                layer = 11, -- on layer13, these objects won't be part of the glow effect
                size = trackWidth * 2,
                renderqueue = 2002,
                percentringed = .27,
                airtexture = ringTexture,
                airshader = "VertexColorUnlitTintedAlpha2",
                airsize = 16
            }
        end
    end
end --End of ring section

do --Waves (Or wakes, as seen in wakeboard mode)
    wakeHeight = 2
    if wakeboard then
        wakeHeight = 2.5
    else
        wakeHeight = 0
    end
    SetWake {
        --setup the spray coming from the two pulling "boats"
        height = wakeHeight,
        fallrate = 0.95,
        shader = "VertexColorUnlitTintedAddSmooth",
        layer = 13, -- looks better not rendered in background when water surface is not type 2
        bottomcolor = "highway",
        topcolor = "highway"
    }
end --End of waves section

do --End of track object (Also known as endcookie)
    if quality < 2 then
        portalTexture = "textures/end/Portal_Low.png"
    elseif quality < 3 then
        portalTexture = "textures/end/Portal_Med.png"
    elseif quality < 4 then
        portalTexture = "textures/end/Portal_High.png"
    else
        portalTexture = "textures/end/Portal_Ultra.png"
    end

    if quality < 2 then
        endLayer = 13
    else
        endLayer = 19
    end

    CreateObject {
        name = "EndCookie_portal",
        tracknode = "end",
        visible = false,
        gameobject = {
            transform = {pos = {0, 0, -18}, scale = {50, 50, 50}},
            mesh = "models/end/portal.obj",
            shader = "IlluminDiffuse",
            texture = portalTexture,
            --lookat = "camera",
            layer = endLayer,
            shadercolors = {
                _Color = "highway"
            }
        }
    }

    CreateObject {
        name = "EndCookie_outershell",
        tracknode = "end",
        gameobject = {
            transform = {pos = {0, 0, -18}, scale = {50, 50, 50}},
            mesh = "models/end/outher.obj",
            shader = "IlluminDiffuse",
            texture = portalTexture,
            --lookat = "camera",
            layer = 19,
            shadercolors = {
                _Color = {99, 99, 99}
            }
        }
    }

    CreateObject {
        name = "EndCookie_TentInner",
        tracknode = "end",
        visible = false,
        gameobject = {
            transform = {pos = {0, 0, 15}, scale = {50, 50, 50}},
            mesh = "models/end/tent.obj",
            shader = "IlluminDiffuse",
            --lookat = "camera",
            texture = "textures/scene/White.png",
            layer = 19,
            shadercolors = {
                _Color = "highway"
            }
        }
    }

    CreateObject {
        name = "EndCookie_TentOuter",
        tracknode = "end",
        visible = false,
        gameobject = {
            transform = {pos = {0, 0, 15}, scale = {50, 50, 50}},
            mesh = "models/end/tent chell.obj",
            shader = "IlluminDiffuse",
            --lookat = "camera",
            texture = "textures/scene/White.png",
            layer = 19,
            shadercolors = {
                _Color = {230, 230, 230}
            }
        }
    }

    if endCookieNode == nil then
        local buildingRotatAnimation = {}
        local buildingRotatAnimation2 = {}
        local endCookieNode = {}
        local offsets = {}
        for i = 1, #track do
            if i % 1000 == 0 then
                buildingRotatAnimation[#buildingRotatAnimation + 1] = {0, 0, 11}
                buildingRotatAnimation2[#buildingRotatAnimation2 + 1] = {0, 0, -11}
                endCookieNode[#endCookieNode + 1] = #track
                offsets[#offsets + 1] = {0, 0, 0}
                break
            end
        end
        BatchRenderEveryFrame {
            prefabName = "EndCookie_TentInner", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
            locations = endCookieNode,
            rotateWithTrack = true,
            rotationspeeds = buildingRotatAnimation,
            maxShown = 1,
            maxDistanceShown = 100000,
            offsets = offsets,
            collisionLayer = -1,
             --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
            testAndHideIfCollideWithTrack = false --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
        }
        BatchRenderEveryFrame {
            prefabName = "EndCookie_TentOuter", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
            locations = endCookieNode,
            rotateWithTrack = true,
            rotationspeeds = buildingRotatAnimation,
            maxShown = 1,
            maxDistanceShown = 100000,
            offsets = offsets,
            collisionLayer = -1,
             --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
            testAndHideIfCollideWithTrack = false --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
        }
        BatchRenderEveryFrame {
            prefabName = "EndCookie_portal", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
            locations = endCookieNode,
            rotateWithTrack = true,
            rotationspeeds = buildingRotatAnimation2,
            maxShown = 1,
            maxDistanceShown = 100000,
            offsets = offsets,
            collisionLayer = -1,
             --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
            testAndHideIfCollideWithTrack = false --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
        }
    end
end --End of end object section

do --Background buildings
    if showBackgroundBuilding then
        if quality >= 3 then
            --Disks
            local buildingMesh =
                BuildMesh {
                mesh = "models/background/disks/disk.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }
            CreateObject {
                name = "Disks",
                tracknode = "start",
                gameobject = {
                    mesh = buildingMesh,
                    shader = "VertexColorUnlitTintedAlpha2",
                    shadercolors = {
                        _Color = "highway"
                    },
                    transform = {scale = {scaletype = "intensity", min = {20, 90, 20}, max = {90, 90, 90}}},
                    texture = "textures/rail/cliff side.png",
                    layer = 19
                }
            }
            local buildingMesh_1 =
                BuildMesh {
                mesh = "models/background/disks/disksupport.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }
            CreateObject {
                name = "DisksPole",
                tracknode = "start",
                gameobject = {
                    mesh = buildingMesh_1,
                    shader = "VertexColorUnlitTintedAlpha2",
                    shadercolors = {
                        _Color = "highway"
                    },
                    transform = {scale = {45, 90, 45}},
                    texture = "textures/rail/cliff side.png",
                    layer = 19
                }
            }
            if buildingNodes == nil then
                local buildingRotatAnimation = {}
                local buildingNodes = {}
                offsets = {}
                for i = 1, #track do
                    if i % 220 == 0 then
                        buildingRotatAnimation[#buildingRotatAnimation + 1] = {0, 0, 0}
                        buildingNodes[#buildingNodes + 1] = i
                        local xOffset = 220 + 1650 * math.random()
                        local yOffset = math.random(0, 140)
                        local zOffset = math.random(-6, 6)
                        if xOffset < 300 then
                            xOffset = 670
                        end
                        if math.random() > 0.4 then
                            xOffset = xOffset * -1
                        end
                        offsets[#offsets + 1] = {xOffset, yOffset, zOffset}
                    end
                end
                BatchRenderEveryFrame {
                    prefabName = "Disks", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
                    locations = buildingNodes,
                    rotateWithTrack = false,
                    rotationspeeds = buildingRotatAnimation,
                    maxShown = 550,
                    maxDistanceShown = 2000,
                    offsets = offsets,
                    collisionLayer = -4,
                     --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = true --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                }
                BatchRenderEveryFrame {
                    prefabName = "DisksPole", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
                    locations = buildingNodes,
                    rotateWithTrack = false,
                    rotationspeeds = buildingRotatAnimation,
                    maxShown = 250,
                    maxDistanceShown = 2000,
                    offsets = offsets,
                    collisionLayer = -4,
                     --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = true --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                }
            end

            --Pyramid
            if quality < 4 then
                pyramidTexture = "textures/backgroundBuildings/pyramid/PyramidShade_High.png"
            else
                pyramidTexture = "textures/backgroundBuildings/pyramid/PyramidShade_Ultra.png"
            end
            local buildingMesh2 =
                BuildMesh {
                mesh = "models/background/pyramid/pyramid.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }
            local buildingMesh2_1 =
                BuildMesh {
                mesh = "models/background/pyramid/pyramidGlow.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }
            CreateObject {
                name = "Pyramid",
                visible = false,
                gameobject = {
                    visible = false,
                    pos = {0, 0, 0},
                    scale = {130, 130, 130},
                    transform = {rot = {180, 0, 0}},
                    mesh = buildingMesh2,
                    renderqueue = 1998,
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = {255, 255, 255}
                    },
                    texture = pyramidTexture,
                    layer = 19
                }
            }
            CreateObject {
                name = "PyramidGlow",
                visible = false,
                gameobject = {
                    visible = false,
                    pos = {0, 0, 0},
                    scale = {130, 130, 130},
                    transform = {rot = {180, 0, 0}},
                    mesh = buildingMesh2_1,
                    renderqueue = 1998,
                    shader = "IlluminDiffuse",
                    shadercolors = {
                        _Color = "highway"
                    },
                    texture = pyramidTexture,
                    layer = 19
                }
            }
            if buildingNodes2 == nil then
                local buildingNodes2 = {}
                local buildingRot = {}
                offsets = {}
                for i = 1, #track do
                    if
                        i % 2830 == 0 and track[i].intensity > 0.09 and track[i].intensity < 0.61 and not track[i].funkyrot and song < 0.83 then
                        buildingNodes2[#buildingNodes2 + 1] = i
                        buildingRot[#buildingRot + 1] = {180, 0, 0}
                        local xOffset = 560
                        offsets[#offsets + 1] = {xOffset, 220, 0}
                    end
                end

                BatchRenderEveryFrame {
                    prefabName = "Pyramid", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
                    locations = buildingNodes2,
                    rotateWithTrack = false,
                    rotations = buildingRot,
                    maxShown = 3,
                    maxDistanceShown = 2000,
                    offsets = offsets,
                    collisionLayer = -2,
                     --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = true --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                }
                BatchRenderEveryFrame {
                    prefabName = "PyramidGlow", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
                    locations = buildingNodes2,
                    rotateWithTrack = false,
                    rotations = buildingRot,
                    maxShown = 3,
                    maxDistanceShown = 2000,
                    offsets = offsets,
                    collisionLayer = -2,
                     --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = true --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                }
            end

            --That flying one headed thingy I don't know what to call it
            if quality < 4 then
                clingTexture = "textures/backgroundBuildings/flydart/ClingderShader_High.png"
            else
                clingTexture = "textures/backgroundBuildings/flydart/ClingderShader_Ultra.png"
            end
            local buildingMesh4 =
                BuildMesh {
                mesh = "models/background/flydart.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }
            CreateObject {
                name = "FlyingThing",
                visible = false,
                tracknode = "start",
                gameobject = {
                    transform = {pos = {0, 0, 0}, scale = {3, 3, 3}},
                    mesh = buildingMesh4,
                    shader = "IlluminDiffuse",
                    texture = clingTexture,
                    layer = 13,
                    shadercolors = {
                        _Color = "highway"
                    }
                }
            }
            if buildingNodes3 == nil then
                local buildingNodes3 = {}
                local buildingRotateAnimation = {}
                offsets = {}
                for i = 1, #track do
                    if i % 1200 == 0 and not track[i].funkyrot and song < 0.83 then
                        buildingNodes3[#buildingNodes3 + 1] = i
                        buildingRotateAnimation[#buildingRotateAnimation + 1] = {0, 370, 0}
                        local xOffset = 90 --Distance between building and track along X-axis (left and right)
                        if math.random(0, 1) > 0.4 then
                            xOffset = xOffset * -1
                        end --Randomize rather the building appear left or right of the track
                        offsets[#offsets + 1] = {xOffset, 2, 0} --Building offset on {x,y,z}
                    end
                end

                BatchRenderEveryFrame {
                    prefabName = "FlyingThing", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
                    locations = buildingNodes3,
                    rotateWithTrack = true,
                    rotationspeeds = buildingRotateAnimation,
                    maxShown = 5,
                    maxDistanceShown = 2000,
                    offsets = offsets,
                    collisionLayer = -7,
                     --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = false --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                }
            end

            --Disco ball
            if quality < 4 then
                clingTexture = "textures/backgroundBuildings/disco/Discoball_solid_High.png"
            else
                clingTexture = "textures/backgroundBuildings/disco/Discoball_solid_Ultra.png"
            end
            local buildingMesh5 =
                BuildMesh {
                mesh = "models/background/discoball.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }
            CreateObject {
                name = "Discoball",
                tracknode = "start",
                visible = false,
                gameobject = {
                    transform = {pos = {0, 0, 0}, scale = {35, 35, 35}},
                    mesh = buildingMesh5,
                    shader = "IlluminDiffuse",
                    texture = clingTexture,
                    layer = 13,
                    shadercolors = {
                        _Color = "highway"
                    }
                }
            }
            if buildingNodes5 == nil then
                local buildingNodes5 = {}
                offsets = {}
                for i = 1, #track do
                    if i % 1350 == 0 and not track[i].funkyrot and song < 0.84 then
                        buildingNodes5[#buildingNodes5 + 1] = i
                        local xOffset = 216 --Distance between building and track along X-axis (left and right)
                        if math.random(0, 1) > 0.5 then
                            xOffset = xOffset * -1
                        end --Randomize rather the building appear left or right of the track
                        offsets[#offsets + 1] = {xOffset, 6, 0} --Building offset on {x,y,z}
                    end
                end

                BatchRenderEveryFrame {
                    prefabName = "Discoball", --Tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
                    locations = buildingNodes5,
                    rotateWithTrack = true,
                    maxShown = 5,
                    maxDistanceShown = 2000,
                    offsets = offsets,
                    collisionLayer = -2, --Will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = true --If true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                }
            end

            --Dancing Blocks
            if quality < 4 then
                clingTexture = "textures/backgroundBuildings/blockDance/BlockDance_High.png"
            else
                clingTexture = "textures/backgroundBuildings/blockDance/BlockDance_Ultra.png"
            end
            local buildingMesh6 =
                BuildMesh {
                mesh = "models/background/danceblock.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }
            CreateObject {
                name = "BlockDance",
                tracknode = "start",
                visible = false,
                gameobject = {
                    transform = {pos = {0, 0, 0}, scale = {12, 12, 12}},
                    mesh = buildingMesh6,
                    shader = "IlluminDiffuse",
                    texture = clingTexture,
                    layer = 13,
                    shadercolors = {
                        _Color = "highway"
                    }
                }
            }
            if buildingNodes6 == nil then
                local buildingNodes6 = {}
                local buildingRotateAnimation = {}
                offsets = {}
                for i = 1, #track do
                    if i % 1210 == 0 and not track[i].funkyrot and song < 0.83 then
                        buildingNodes6[#buildingNodes6 + 1] = i
                        buildingRotateAnimation[#buildingRotateAnimation + 1] = {0, 200, 0}
                        local xOffset = 330 --Distance between building and track along X-axis (left and right)
                        if math.random(0, 1) > 0.5 then
                            xOffset = xOffset * -1
                        end --Randomize rather the building appear left or right of the track
                        offsets[#offsets + 1] = {xOffset, 0, 0} --Building offset on {x,y,z}
                    end
                end

                BatchRenderEveryFrame {
                    prefabName = "BlockDance", --tell the game to render these prefabs in a batch (with Graphics.DrawMesh) every frame
                    locations = buildingNodes6,
                    rotateWithTrack = true,
                    rotationspeeds = buildingRotateAnimation,
                    maxShown = 5,
                    maxDistanceShown = 2000,
                    offsets = offsets,
                    collisionLayer = -3,
                     
                    testAndHideIfCollideWithTrack = false 
                }
            end
        end --endif quality >= 3
    end --endif showBackgroundBuilding
end --End of building section

do --Rails
    -- rails are the bulk of the graphics in audiosurf. Each one is a 2D shape extruded down the length of the track.
	
    --CreateRepeatedMeshRail {
    --    prefabName = "RailSide",
    --    colorMode = "static",
    --    buildlive = false,
    --   spacing = 150,
    --    calculatenormals = false
    --}

    if not wakeboard then
        local laneDividers = skinvars["lanedividers"]
        for i = 1, #laneDividers do
            CreateRail {
                -- lane line
                positionOffset = {
                    x = laneDividers[i],
                    y = 0.1
                },
                crossSectionShape = {
                    {x = -.07, y = 0},
                    {x = .07, y = 0}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "static",
                color = {r = 200, g = 200, b = 200},
                flatten = false,
                nodeskip = 2,
				fullfuture = showEntireRoad,
                wrapnodeshape = false,
                shader = "VertexColorUnlitTinted"
            }
        end
    end

    if not wakeboard then
        local shoulderLines = skinvars["shoulderlines"]
        for i = 1, #shoulderLines do
            CreateRail {
                --shoulder lane
                positionOffset = {
                    x = shoulderLines[i] - 0.19,
                    y = 0.05
                },
                crossSectionShape = {
                    {x = -.04, y = .01},
                    {x = .04, y = .01},
                    {x = .04, y = -.01},
                    {x = -.04, y = -.01}
                },
                perShapeNodeColorScalers = {
                    .8,
                    1,
                    .8,
                    .8
                },
                colorMode = "static",
                color = {r = 101, g = 101, b = 101},
                flatten = false,
                fullfuture = false,
                shadowcaster = false,
                shadowreceiver = false,
                calculatenormals = true,
                shader = "DiffuseVertexColored2",
                shadercolors = {
                    _Color = {r = 0, g = 0, b = 0}
                },
                layer = 13
            }
        end
    end

    --        left rail upperleft outline O-------------------O left rail upperright outline         	   right rail upperleft outline	O-------------------O right rail upperright outline
    --        							  |                   |                  														|                   |
    --        							  |                   |                  														|                   |
    --        							  |                   | left rail bottomright outline             right rail bottomleft outline |                   |
    --        							  |                   O                  														O                   |
    --        							  |    (left rail)    | ----------------------------------------------------------------------- |    (right rail)   |
    --        							  |                   |                  			(Road surface)							    |                   |
    --        							  |                   |                  														|                   |
    --        							  |                   |                  														|                   |
    --        							  |                   |                  														|                   |
    --       left rail bottomleft outline O--------------------                                                                         --------------------O right rail bottomright outline

    if not wakeboard then
        CreateRail {
            --Road surface
            positionOffset = {
                x = 0,
                y = 0
            },
            crossSectionShape = {
                {x = -trackWidth, y = 0},
                {x = trackWidth, y = 0}
            },
            perShapeNodeColorScalers = {
                1,
                1
            },
            colorMode = "static",
            layer = 12,
            color = {r = 251, g = 251, b = 251, a = 238},
            renderqueue = 2001,
			fullfuture = showEntireRoad,
            flatten = false,
            shader = "VertexColorUnlitTintedAlpha"
        }
    end

    if not wakeboard then
        CreateRail {
            --left rail
            positionOffset = {
                x = -trackWidth - .2,
                y = 0
            },
            crossSectionShape = {
                {x = -.64, y = 0.49},
                {x = .29, y = 0.49},
                {x = .29, y = -0.49},
                {x = -.64, y = -0.49}
            },
            perShapeNodeColorScalers = {
                .9,
                .9,
                .9,
                .9
            },
            colorMode = "highway",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            renderqueue = 1999,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = true,
            calculatenormals = false,
            shader = "DiffuseVertexColored2",
            shadercolors = {_Color = "highway", a = 50},
            layer = 13
        }

        CreateRail {
            --left rail light
            positionOffset = {
                x = -trackWidth - .2,
                y = 0
            },
            crossSectionShape = {
                {x = -.65, y = 0.5},
                {x = .3, y = 0.5},
                {x = .3, y = -0.01},
                {x = -.65, y = -0.01}
            },
            perShapeNodeColorScalers = {
                .9,
                .9
            },
            colorMode = "static",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            renderqueue = 2001,
            wrapnodeshape = false,
            texture = "textures/rail/left rail light.png",
            fullfuture = showEntireRoad,
            calculatenormals = false,
            shader = "VertexColorUnlitTintedAlpha",
            layer = 13
        }

        CreateRail {
            --left rail outward light
            positionOffset = {
                x = -trackWidth - .2,
                y = 0
            },
            crossSectionShape = {
                {x = -.66, y = -0.55},
                {x = -.66, y = 0.5}
            },
            perShapeNodeColorScalers = {
                .9,
                .9
            },
            colorMode = "static",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            wrapnodeshape = false,
            texture = "textures/rail/left rail light.png",
            fullfuture = showEntireRoad,
            calculatenormals = false,
            shader = "VertexColorUnlitTintedAlpha2",
            layer = 13
        }

        CreateRail {
            --left rail reflection light
            positionOffset = {
                x = -trackWidth - .2,
                y = 0
            },
            crossSectionShape = {
                {x = -.64, y = 0},
                {x = 0.30, y = 0},
                {x = 0.30, y = -0.56},
                {x = -.64, y = -0.56}
            },
            perShapeNodeColorScalers = {
                .9,
                .9
            },
            colorMode = "static",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            renderqueue = 2000,
            wrapnodeshape = false,
            texture = "textures/rail/left rail light.png",
            textureMode = "repeataroundreverse",
            fullfuture = showEntireRoad,
            calculatenormals = false,
            shader = "VertexColorUnlitTintedAlpha",
            layer = 13
        }

        CreateRail {
            --left rail upperright outline
            positionOffset = {
                x = -trackWidth + 0.1,
                y = 0.5
            },
            crossSectionShape = {
                {x = -.01, y = .01},
                {x = .01, y = .01},
                {x = .01, y = -.01},
                {x = -.01, y = -.01}
            },
            perShapeNodeColorScalers = {
                .8,
                1,
                .8,
                .8
            },
            colorMode = "static",
            color = {r = 55, g = 55, b = 55},
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = "DiffuseVertexColored2",
            shadercolors = {
                _Color = {r = 0, g = 0, b = 0}
            },
            layer = 13
        }

        CreateRail {
            --right rail upperleft outline
            positionOffset = {
                x = trackWidth - 0.46,
                y = 0.5
            },
            crossSectionShape = {
                {x = -.01, y = .01},
                {x = .01, y = .01},
                {x = .01, y = -.01},
                {x = -.01, y = -.01}
            },
            perShapeNodeColorScalers = {
                .8,
                1,
                .8,
                .8
            },
            colorMode = "static",
            color = {r = 55, g = 55, b = 55},
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = "DiffuseVertexColored2",
            shadercolors = {
                _Color = {r = 0, g = 0, b = 0}
            },
            layer = 13
        }

        CreateRail {
            --right rail upperright outline
            positionOffset = {
                x = trackWidth + 0.5,
                y = 0.5
            },
            crossSectionShape = {
                {x = -.01, y = .01},
                {x = .01, y = .01},
                {x = .01, y = -.01},
                {x = -.01, y = -.01}
            },
            perShapeNodeColorScalers = {
                .8,
                1,
                .8,
                .8
            },
            colorMode = "static",
            color = {r = 55, g = 55, b = 55},
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = "DiffuseVertexColored2",
            shadercolors = {
                _Color = {r = 0, g = 0, b = 0}
            },
            layer = 13
        }

        CreateRail {
            --right rail bottomleft outline
            positionOffset = {
                x = trackWidth - 0.45,
                y = 0
            },
            crossSectionShape = {
                {x = -.03, y = .01},
                {x = .03, y = .01},
                {x = .03, y = -.01},
                {x = -.03, y = -.01}
            },
            perShapeNodeColorScalers = {
                .8,
                1,
                .8,
                .8
            },
            colorMode = "static",
            color = {r = 55, g = 55, b = 55},
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = "DiffuseVertexColored2",
            shadercolors = {
                _Color = {r = 0, g = 0, b = 0}
            },
            layer = 13
        }

        CreateRail {
            --left rail bottomright outline
            positionOffset = {
                x = -trackWidth + 0.10,
                y = 0
            },
            crossSectionShape = {
                {x = -.02, y = .01},
                {x = .02, y = .01},
                {x = .02, y = -.01},
                {x = -.02, y = -.01}
            },
            perShapeNodeColorScalers = {
                .8,
                1,
                .8,
                .8
            },
            colorMode = "static",
            color = {r = 55, g = 55, b = 55},
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = "DiffuseVertexColored2",
            shadercolors = {
                _Color = {r = 0, g = 0, b = 0}
            },
            layer = 13
        }

        CreateRail {
            --left rail upper left outline
            positionOffset = {
                x = -trackWidth - 0.86,
                y = 0.5
            },
            crossSectionShape = {
                {x = -.01, y = .01},
                {x = .01, y = .01},
                {x = .01, y = -.01},
                {x = -.01, y = -.01}
            },
            perShapeNodeColorScalers = {
                .8,
                1,
                .8,
                .8
            },
            colorMode = "static",
            color = {r = 55, g = 55, b = 55},
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = "DiffuseVertexColored2",
            shadercolors = {
                _Color = {r = 255, g = 255, b = 255}
            },
            layer = 13
        }

        CreateRail {
            --right rail
            positionOffset = {
                x = trackWidth + .2,
                y = 0
            },
            crossSectionShape = {
                {x = -.63, y = 0.49},
                {x = .31, y = 0.49},
                {x = .31, y = -0.49},
                {x = -.63, y = -0.49}
            },
            perShapeNodeColorScalers = {
                .9,
                .9,
                .9,
                .9
            },
            colorMode = "highway",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            fullfuture = showEntireRoad,
            renderqueue = 1999,
            shadowcaster = false,
            shadowreceiver = true,
            calculatenormals = false,
            shader = "VertexColorLitTinedAdd",
            shadercolors = {_Color = "highway", a = 50},
            layer = 13
        }

        CreateRail {
            --right rail light
            positionOffset = {
                x = trackWidth + .2,
                y = 0
            },
            crossSectionShape = {
                {x = -.64, y = 0},
                {x = -.64, y = 0.5},
                {x = .33, y = 0.5},
                {x = .33, y = 0.5}
            },
            perShapeNodeColorScalers = {
                .9,
                .9
            },
            colorMode = "static",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            renderqueue = 2001,
            wrapnodeshape = false,
            texture = "textures/rail/right rail light.png",
            textureMode = "repeataroundreverse",
            fullfuture = showEntireRoad,
            calculatenormals = false,
            shader = "VertexColorUnlitTintedAlpha",
            layer = 13
        }

        CreateRail {
            --right rail reflection light
            positionOffset = {
                x = trackWidth + .2,
                y = 0
            },
            crossSectionShape = {
                {x = 0.30, y = -0.56},
                {x = -.64, y = -0.56},
                {x = -.64, y = 0},
                {x = 0.30, y = 0}
            },
            perShapeNodeColorScalers = {
                .9,
                .9
            },
            colorMode = "static",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            renderqueue = 2000,
            wrapnodeshape = false,
            texture = "textures/rail/right rail light.png",
            textureMode = "repeataroundreverse",
            fullfuture = showEntireRoad,
            calculatenormals = false,
            shader = "VertexColorUnlitTintedAlpha",
            layer = 13
        }

        CreateRail {
            --right rail outward light
            positionOffset = {
                x = trackWidth + .2,
                y = 0
            },
            crossSectionShape = {
                {x = 0.32, y = 0.5},
                {x = 0.32, y = -0.55}
            },
            perShapeNodeColorScalers = {
                .9,
                .9
            },
            colorMode = "static",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            renderqueue = 2004,
            wrapnodeshape = false,
            texture = "textures/rail/right rail light.png",
            fullfuture = showEntireRoad,
            calculatenormals = false,
            shader = "VertexColorUnlitTintedAlpha2",
            layer = 13
        }
    end

    --                 Left rail O______________O Right rail
    --							  (Road surface)
    --							/				\
    --	      (Left cliff)	/						\ (Right cliff)
    --					/								\
    --				X (Cliff outline)	    (Cliff outline) X
    --			/												\
    --		   |												 |
    --		   | (Left side cliff)			   (Right side cliff)|
    --		   |												 |
    --		   X (Cliff outline)				 (Cliff outline) X
    --		   |												 |

    if not wakeboard then
        if not oneColorCliff then
            CreateRail {
                --right cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = trackWidth + 14, y = -11},
                    {x = trackWidth + 33, y = -20},
                    {x = trackWidth + 44.5, y = -29}
                },
                perShapeNodeColorScalers = {
                    1,
                    1,
                    1,
                    1
                },
                colorMode = "hallway",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                behind_renderdist = 10,
                wrapnodeshape = false,
                texture = "textures/rail/big cliff.png",
                fullfuture = true,
                stretch = math.ceil(#track * 3 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                layer = 13
            }

            CreateRail {
                --left cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = -trackWidth - 43, y = -29},
                    {x = -trackWidth - 33, y = -20},
                    {x = -trackWidth - 14, y = -11}
                },
                perShapeNodeColorScalers = {
                    1,
                    1,
                    1,
                    1
                },
                colorMode = "hallway",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/big cliff.png",
                fullfuture = true,
                stretch = math.ceil(#track * 3 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                layer = 13
            }

            CreateRail {
                --left side cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = -trackWidth - 43, y = -80},
                    {x = -trackWidth - 43, y = -29}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "hallway",
                --colorMode="static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side2.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                --shadercolors={
                --		_Color = "highway"
                --	},
                layer = 13
            }

            CreateRail {
                --right side cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = trackWidth + 44, y = -29},
                    {x = trackWidth + 44, y = -80}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "highway",
                --colorMode="static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                --shadercolors={
                --		_Color = "highway"
                --	},
                layer = 13
            }

            CreateRail {
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = -trackWidth - 14, y = -11},
                    {x = -trackWidth - 0, y = -11}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "highway",
                --colorMode="static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                --shadercolors={
                --		_Color = "highway"
                --	},
                layer = 13
            }

            CreateRail {
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = trackWidth + 0, y = -11},
                    {x = trackWidth + 14, y = -11}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "highway",
                --colorMode="static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side2.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                --shadercolors={
                --		_Color = "highway"
                --	},
                layer = 13
            }
        else
            CreateRail {
                --right cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = trackWidth + 14, y = -11},
                    {x = trackWidth + 33, y = -20},
                    {x = trackWidth + 44.5, y = -29}
                },
                perShapeNodeColorScalers = {
                    1,
                    1,
                    1,
                    1
                },
                colorMode = "static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                behind_renderdist = 10,
                wrapnodeshape = false,
                texture = "textures/big cliff.png",
                fullfuture = true,
                stretch = math.ceil(#track * 3 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = {
                    _Color = "highway"
                },
                layer = 13
            }

            CreateRail {
                --left cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = -trackWidth - 43, y = -29},
                    {x = -trackWidth - 33, y = -20},
                    {x = -trackWidth - 14, y = -11}
                },
                perShapeNodeColorScalers = {
                    1,
                    1,
                    1,
                    1
                },
                colorMode = "static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/big cliff.png",
                fullfuture = true,
                stretch = math.ceil(#track * 3 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = {
                    _Color = "highway"
                },
                layer = 13
            }

            CreateRail {
                --left side cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = -trackWidth - 43, y = -80},
                    {x = -trackWidth - 43, y = -29}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side2.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = {
                    _Color = "highway"
                },
                layer = 13
            }

            CreateRail {
                --right side cliff
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = trackWidth + 44, y = -29},
                    {x = trackWidth + 44, y = -80}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = {
                    _Color = "highway"
                },
                layer = 13
            }

            CreateRail {
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = -trackWidth - 14, y = -11},
                    {x = -trackWidth - 0, y = -11}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = {
                    _Color = "highway"
                },
                layer = 13
            }

            CreateRail {
                positionOffset = {
                    x = 0,
                    y = 0
                },
                crossSectionShape = {
                    {x = trackWidth + 0, y = -11},
                    {x = trackWidth + 14, y = -11}
                },
                perShapeNodeColorScalers = {
                    1,
                    1
                },
                colorMode = "static",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side2.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = {
                    _Color = "highway"
                },
                layer = 13
            }
        end

        CreateRail {
            --Cliff outline, recommend any changes apply to all cliff outlines
            positionOffset = {
                x = -trackWidth - 43,
                y = -29
            },
            crossSectionShape = {
                {x = 0, y = -0.2},
                {x = -.2, y = -0.2},
                {x = -.2, y = 0},
                {x = 0, y = 0}
            },
            colorMode = "static",
            color = {r = 80, g = 80, b = 80},
            flatten = false,
            fullfuture = false,
            shadowcaster = false,
            shadowreceiver = true,
            calculatenormals = false,
            shader = "DiffuseVertexColored2",
            shadercolors = {55, 55, 55},
            layer = 13
        }

        CreateRail {
            --Cliff outline, recommend any changes apply to all cliff outlines
            positionOffset = {
                x = trackWidth + 44.5,
                y = -29
            },
            crossSectionShape = {
                {x = 0, y = 0.2},
                {x = .2, y = 0.2},
                {x = .2, y = 0},
                {x = 0, y = 0}
            },
            colorMode = "static",
            color = {r = 80, g = 80, b = 80},
            flatten = false,
            fullfuture = false,
            shadowcaster = false,
            shadowreceiver = true,
            calculatenormals = false,
            shader = "DiffuseVertexColored2",
            shadercolors = {55, 55, 55},
            layer = 13
        }

        CreateRail {
            --Cliff outline, recommend any changes apply to all cliff outlines
            positionOffset = {
                x = -trackWidth - 14,
                y = -11
            },
            crossSectionShape = {
                {x = 0, y = -0.2},
                {x = -.2, y = -0.2},
                {x = -.2, y = 0},
                {x = 0, y = 0}
            },
            colorMode = "static",
            color = {r = 80, g = 80, b = 80},
            flatten = false,
            fullfuture = false,
            shadowcaster = false,
            shadowreceiver = true,
            calculatenormals = false,
            shader = "DiffuseVertexColored2",
            shadercolors = {55, 55, 55},
            layer = 13
        }

        CreateRail {
            --Cliff outline, recommend any changes apply to all cliff outlines
            positionOffset = {
                x = trackWidth + 14,
                y = -11
            },
            crossSectionShape = {
                {x = 0, y = 0.2},
                {x = .2, y = 0.2},
                {x = .2, y = 0},
                {x = 0, y = 0}
            },
            colorMode = "static",
            color = {r = 80, g = 80, b = 80},
            flatten = false,
            fullfuture = false,
            shadowcaster = false,
            shadowreceiver = true,
            calculatenormals = false,
            shader = "DiffuseVertexColored2",
            shadercolors = {55, 55, 55},
            layer = 13
        }
    end

    if wakeboard then
		if not oneColorCliff then
			CreateRail {
				--Wakeboard wide cliff
				positionOffset = {
					x = 0,
					y = 0
				},
				crossSectionShape = {
					{x = trackWidth + 11, y = -4},
					{x = trackWidth + 28, y = -13},
					{x = trackWidth + 36.5, y = -18},
					{x = -trackWidth - 36.5, y = -18},
					{x = -trackWidth + 36.5 - 28, y = -13},
					{x = -trackWidth + 36.5 - 11, y = -4}
				},
				perShapeNodeColorScalers = {
					1,
					1,
					1,
					1
				},
				colorMode = "highway",
				color = {r = 255, g = 255, b = 255},
				flatten = false,
				wrapnodeshape = true,
				texture = "textures/big cliff.png",
				fullfuture = true,
				stretch = math.ceil(#track * 6 / 63500),
				calculatenormals = false,
				allowfullmaterialoptions = false,
				shader = "VertexColorUnlitTintedAlpha2",
				layer = 13
			}

			CreateRail {
				--Cliff outline, recommend any changes apply to all cliff outlines
				positionOffset = {
					x = -trackWidth - 36.5,
					y = -17.5
				},
				crossSectionShape = {
					{x = 0, y = 0.2},
					{x = .4, y = 0.2},
					{x = .4, y = 0},
					{x = 0, y = 0}
				},
				colorMode = "static",
				color = {r = 255, g = 255, b = 255},
				flatten = false,
				fullfuture = false,
				shadowcaster = false,
				shadowreceiver = true,
				calculatenormals = false,
				shader = "Diffuse",
				shadercolors = {0, 0, 0},
				layer = 13
			}

			CreateRail {
				--Cliff outline, recommend any changes apply to all cliff outlines
				positionOffset = {
					x = trackWidth + 36.5,
					y = -17.5
				},
				crossSectionShape = {
					{x = 0, y = -0.2},
					{x = -.4, y = -0.2},
					{x = -.4, y = 0},
					{x = 0, y = 0}
				},
				colorMode = "static",
				color = {r = 255, g = 255, b = 255},
				flatten = false,
				fullfuture = false,
				shadowcaster = false,
				shadowreceiver = true,
				calculatenormals = false,
				shader = "Diffuse",
				shadercolors = {0, 0, 0},
				layer = 13
			}
		else
			CreateRail {
				--Wakeboard wide cliff
				positionOffset = {
					x = 0,
					y = 0
				},
				crossSectionShape = {
					{x = trackWidth + 11, y = -4},
					{x = trackWidth + 28, y = -13},
					{x = trackWidth + 36.5, y = -18},
					{x = -trackWidth - 36.5, y = -18},
					{x = -trackWidth + 36.5 - 28, y = -13},
					{x = -trackWidth + 36.5 - 11, y = -4}
				},
				perShapeNodeColorScalers = {
					1,
					1,
					1,
					1
				},
				colorMode = "static",
				color = {r = 255, g = 255, b = 255},
				flatten = false,
				wrapnodeshape = true,
				texture = "textures/big cliff.png",
				fullfuture = true,
				stretch = math.ceil(#track * 6 / 63500),
				calculatenormals = false,
				allowfullmaterialoptions = false,
				shader = "VertexColorUnlitTintedAlpha2",
				shadercolors={
						_Color = "highway"
				},
				layer = 13
			}

			CreateRail {
				--Cliff outline, recommend any changes apply to all cliff outlines
				positionOffset = {
					x = -trackWidth - 36.5,
					y = -17.5
				},
				crossSectionShape = {
					{x = 0, y = 0.2},
					{x = .4, y = 0.2},
					{x = .4, y = 0},
					{x = 0, y = 0}
				},
				colorMode = "static",
				color = {r = 255, g = 255, b = 255},
				flatten = false,
				fullfuture = false,
				shadowcaster = false,
				shadowreceiver = true,
				calculatenormals = false,
				shader = "Diffuse",
				shadercolors = {0, 0, 0},
				layer = 13
			}
	
			CreateRail {
				--Cliff outline, recommend any changes apply to all cliff outlines
				positionOffset = {
					x = trackWidth + 36.5,
					y = -17.5
				},
				crossSectionShape = {
					{x = 0, y = -0.2},
					{x = -.4, y = -0.2},
					{x = -.4, y = 0},
					{x = 0, y = 0}
				},
				colorMode = "static",
				color = {r = 255, g = 255, b = 255},
				flatten = false,
				fullfuture = false,
				shadowcaster = false,
				shadowreceiver = true,
				calculatenormals = false,
				shader = "Diffuse",
				shadercolors = {0, 0, 0},
				layer = 13
			}
		end
    end

    -- 		O (left skyline)    (right skyline) O
    --
    --
    --					      O
    --			       ......-|- ......
    --			^......	      /\	   .....^
    --			   ~~~~~~~~~~~~~~~~~~~~~~~~

    if wakeboard then
        CreateRail {
            --left skyline
            positionOffset = {
                x = -18,
                y = 33
            },
            crossSectionShape = {
                {x = -13, y = .5},
                {x = -9, y = .5},
                {x = -9, y = -.5},
                {x = -13, y = -.5}
            },
            perShapeNodeColorScalers = {
                1,
                1,
                1,
                1
            },
            colorMode = "highway",
            color = {r = 255, g = 255, b = 255},
            flatten = true,
            texture = "textures/scene/White.png",
            shader = "VertexColorUnlitTinted"
        }

        CreateRail {
            --right skyline
            positionOffset = {
                x = 18,
                y = 33
            },
            crossSectionShape = {
                {x = 9, y = .5},
                {x = 13, y = .5},
                {x = 13, y = -.5},
                {x = 9, y = -.5}
            },
            perShapeNodeColorScalers = {
                1,
                1,
                1,
                1
            },
            colorMode = "highway",
            color = {r = 255, g = 255, b = 255},
            flatten = true,
            texture = "textures/scene/White.png",
            shader = "VertexColorUnlitTinted"
        }
    end
end --End of rail creation