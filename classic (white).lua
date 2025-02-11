--[[
CLassic (White)

Coded, modeled, and textured by:
* Jiayuan "Weldon" Wen (Website: https://jiayuanwen.github.io)

I take no credit for the overall style, they go to the following parties:
* Dylan Fitterer (Twitter: https://twitter.com/dylanfitterer)
* Girgan Delic (Website: https://www.gorandelic.com/)

Player ship is created and provided by:
Paladin Studios (Website: https://paladinstudios.com/)

Shader information & bug fixes
* DeathByNukes (Socials: https://steamcommunity.com/id/DeathByNukes, Email: dbn@deathbynukes.com)

License: GNU GPLv3, see LICENSE file for details.

]]

--Options
competitiveCamera = false --Set this to true to tweak camera angle for competitive play.
oneColorCliff = false --If this is set to true, the track's cliff will be the same color from begin to end. If set to false, the track's cliff will be in rainbow color.
showEntireRoad = false --If set to true, the entire track is visible. If set to false, the track is loaded section by section during gameplay.
--End of options

--Extra Graphic Options
showRing = true --Toggle ring visibility On/Off.
showBackgroundBuilding = true --Toggle background objects On/Off.
showSkyWire = true --Toggle wires in the sky On/Off.
showAirBubbles = true --Toggle grey bubbles around the track On/Off.
--End of graphic options

--Make sure to save the file before heading back to the game.


---------------------------------------Skin source code--------------------------------------

--------------------------------------------------------------------------------

-- fif shortcut

--------------------------------------------------------------------------------
do --Lua fif shortcut
    function fif(test, if_true, if_false)
        if test then
            return if_true
        else
            return if_false
        end
    end
end --End of fif setup


--------------------------------------------------------------------------------

-- Graphic quality variable

--------------------------------------------------------------------------------
do --Graphic quality variable
    hifi = GetQualityLevel() > 2
    function ifhifi(if_true, if_false)
        if hifi then
            return if_true
        else
            return if_false
        end
    end
    quality = GetQualityLevel4()
end --End of graphic quality variable


--------------------------------------------------------------------------------

-- Common variables

--------------------------------------------------------------------------------
do --Frequent used variables setup
    wakeboard = PlayerCanJump()
    skinvars = GetSkinProperties()
    trackWidth = skinvars["trackwidth"] --trackWidth = fif(wakeboard, 11.5, 7)
    ispuzzle = skinvars.colorcount > 1
    fullsteep = wakeboard or skinvars.prefersteep or (not ispuzzle)
    track = GetTrack() --get the track data from the game engine
    song = GetSongCompletionPercentage()

end --End of frequent used variables section


-----------------------------------------------------------------------------

-- Rail rendering fix for fast game modes

-----------------------------------------------------------------------------
do --Rail rendering fix
    --source: https://as2-doc.deathbynukes.com/shaders.html

    -- START of rail fix for fast modes.
    -- (Put this somewhere between "track = GetTrack()" and your first use of CreateRail.)
    -- (By DeathByNukes, for anyone to use.)
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

end --end of rail rendering fix


--------------------------------------------------------------------------------

-- Skin scene settings

--------------------------------------------------------------------------------
do --Skin scene settings setup
    quality = GetQualityLevel4()

    -- Define debris amount and texture quality base on graphic quality
    if quality < 3 then
        debrisTexture = "textures/scene/FireworkMed.png"
        airdebrisCount = 400
        airdebrisDensity = 50
        blurBool = 0
    elseif quality < 4 then
        debrisTexture = "textures/scene/FireworkHigh.png"
        airdebrisCount = 400
        airdebrisDensity = 50
        blurBool = 0
    else
        debrisTexture = "textures/scene/FireworkUltra.png"
        airdebrisCount = 500
        airdebrisDensity = 50
        blurBool = 1.3
    end

    -- Disable intro camera movement for 'low' quality
    if quality < 2 then
        introCameraBool = false
    else
        introCameraBool = true
    end

    -- Scene settings
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
        airdebris_shader = "VertexColorUnlitTintedAlpha2",
        airdebris_particlesize = 1.3,
        airdebris_flashsizescaler = 1.5,
        airdebris_layer = 13,
        useblackgrid = true,
        minimap_colormode = "black",
        twistmode = {curvescaler = 1, steepscaler = fif(fullsteep, 1, .65)}
    }
end --End of skin scene settings


--------------------------------------------------------------------------------

-- UI settings

--------------------------------------------------------------------------------
do --UI settings

    -- YouTube video appearance settings (deprecated due to different monitor size)
    --SetVideoScreenTransform {
    --    pos = {120, -99.44, 0},
    --    rot = {0, 0, 0},
    --    scale = {10, 6, 3}
    --}
end --End of UI settings

--------------------------------------------------------------------------------

-- Post processing effects

--------------------------------------------------------------------------------
do --Post-processing effects
    if quality >= 4 then
        AddPostEffect {
            depth = "background",
            material = radialBlurEffect
        }
    end
end --End of Post-processing effects


--------------------------------------------------------------------------------

-- Sound effects

--------------------------------------------------------------------------------
do --Sound effects
    if not ispuzzle then
        LoadSounds {
            hit = "sounds/color.wav",
            hitgrey = "sounds/grey.wav",
            hitgreypro = "sounds/grey.wav",
            matchsmall = "sounds/matchmedium.wav"
        }
    end
end --End of sound effects


--------------------------------------------------------------------------------

-- Block settings

--------------------------------------------------------------------------------
do -- Block settings

    -- Define # of visible blocks base on graphic setting
    if quality < 2 then
        blockCount = 35
    elseif quality < 3 then
        blockCount = 50
    elseif quality < 4 then
        blockCount = 75
    else
        blockCount = 100
    end

    -- Block appearance settings
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

    -- Block colors for puzzle modes
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

    -- Specific block appearance setting for puzzle modes
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

end --End of block settings


--------------------------------------------------------------------------------

-- Gameplay graphics

--------------------------------------------------------------------------------
do -- Gameplay graphics

    -- Block hit effect settings
    do
        -- Define hit effect texture quality base on graphic setting
        if quality < 2 then
            hitTexture = "textures/gameplay/hit2Low.png"
        elseif quality < 3 then
            hitTexture = "textures/gameplay/hit2Med.png"
        elseif quality < 4 then
            hitTexture = "textures/gameplay/hit2High.png"
        else
            hitTexture = "textures/gameplay/hit2Ultra.png"
        end

        -- Disable hit effect for 'low' graphic setting
        if quality < 2 then
            hitScaler = 0
            missScaler = 0

        else
            hitScaler = 0.6
            missScaler = 0.4
        end

        SetBlockFlashes {
            texture = hitTexture,
            sizescaler = hitScaler,
            sizescaler_missed = missScaler
        }
    end

    -- Grid settings
    -- (the puzzle grids under the player ship)
    do

        -- Define texture quality base on graphic setting
        local tileTexLevel
        if quality < 2 then
            tileTexLevel = "Low"
        elseif quality < 3 then
            tileTexLevel = "Med"
        elseif quality < 4 then
            tileTexLevel = "High"
        else
            tileTexLevel = "Ultra"
        end
        local tileMatchTex = "textures/gameplay/tileMatchingBarsinvert_" .. tileTexLevel .. ".png"
        local tileFlyupTex = "textures/gameplay/flyup_" .. tileTexLevel .. ".png"
        local tileInvertTex = "textures/gameplay/tilesSquareinvert_" .. tileTexLevel .. ".png"

        -- Grid graphic setting
        SetPuzzleGraphics {
            usesublayerclone = false,
            puzzlematchmaterial = {
                shader = "Unlit/Transparent",
                texture = tileMatchTex,
                shadercolors = "highway",
                aniso = 9,
                layer = 14
            },
            puzzleflyupmaterial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = tileFlyupTex,
                shadercolors = "highway",
                layer = 14
            },
            puzzlematerial = {
                shader = "VertexColorUnlitTintedAlpha2",
                texture = tileInvertTex,
                texturewrap = "clamp",
                aniso = 9,
                usemipmaps = "false",
                shadercolors = {0, 0, 0},
                layer = 14
            }
        }
    end

end --End of gameplay graphics


--------------------------------------------------------------------------------

-- Player ship

--------------------------------------------------------------------------------
do --Player ship

    -- Player ship for mono modes
    if not ispuzzle then
        shipMesh =
            BuildMesh {
            mesh = "models/player/mono.obj",
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
            textures = {_Glow = "textures/player/vehicleM_glow.png", _MainTex = "textures/player/vehicleM.png"}
        }

        ship = {
            min_hover_height = 0.15,
            max_hover_height = 0.9,
            use_water_rooster = false,
            smooth_tilting = true,
            smooth_tilting_speed = 30,
            smooth_tilting_max_offset = -20,
            pos = {x = 0, y = 0, z = 0.20},
            mesh = shipMesh,
            material = shipMaterial,
            shadowreceiver = true,
            layer = 13,
            reflect = true,
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

    -- Player ship for puzzle modes
    if ispuzzle then
        shipMesh =
            BuildMesh {
            mesh = "models/player/puzzle.obj",
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
            textures = {_Glow = "textures/player/vehicleP_glow.png", _MainTex = "textures/player/vehicleP.png"}
        }

        ship = {
            min_hover_height = 0.23,
            max_hover_height = 0.8,
            use_water_rooster = false,
            smooth_tilting = true,
            smooth_tilting_speed = 10,
            smooth_tilting_max_offset = -20,
            pos = {x = 0, y = 0, z = 0},
            mesh = shipMesh,
            material=shipMaterial,
            layer = 13,
            reflect = true,
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

    -- Surfer for wakeboard mode
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
end --End of player ship


--------------------------------------------------------------------------------

-- Skybox

--------------------------------------------------------------------------------
do --Skybox
    -- Skybox texture
    SetSkybox {
        skysphere = "textures/scene/White.png"
    }

    -- Skywire layer adjust base on graphic setting
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

        --Skywire blinks with the music's intensity
        --[[
        function Update(dt, trackLocation, playerStrafe, playerJumpHeight, intensity)
            if skywireMat then
                local greyScale = 255 - (92*intensity)
                UpdateShaderSettings{
                    material = skywireMat,
                    shadercolors={
                        _Color={r=greyScale,g=greyScale,b=greyScale}
                    }
                }
            end
        end]]

        CreateObject {
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
end --End of skybox


--------------------------------------------------------------------------------

-- Track colors

--------------------------------------------------------------------------------
do --Track colors
    SetTrackColors {
        --enter any number of colors here. The track will use the first ones on less intense sections and interpolate all the way to the last one on the most intense sections of the track
        {r = 148, g = 10, b = 253},
        {r = 0, g = 177, b = 252},
        {r = 0, g = 168, b = 0},
        {r = 255, g = 255, b = 0},
        {r = 252, g = 0, b = 0}
    }
end --End of track colors


--------------------------------------------------------------------------------

-- Track rings

--------------------------------------------------------------------------------
do --Rings
    local ringTexture

    -- Ring texture quality base on graphic setting
    local resolution
    do
        if quality < 2 then
            resolution = 420
        elseif quality < 3 then
            resolution = 720
        elseif quality < 4 then
            resolution = 1080
        else
            resolution = 2160
        end

        ringTexture = "textures/ring/Classic" .. resolution .. "p.png"
    end

    -- Increase ring size so it doesn't clip competitve camera
    if competitiveCamera then
        ringSizeMultiplier = 2.5
    else
        ringSizeMultiplier = 2
    end

    -- Ring settings for non wakeboard (mono & puzzle) modes
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

    -- Ring settings for wakeboard mode
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


--------------------------------------------------------------------------------

-- Air bubbles

--------------------------------------------------------------------------------
do --Air Bubbles
    if showAirBubbles then
        local bubbleTexture

        -- Adjust air bubble texture quality base on graphic setting
        local bubbleDensity
        local bubbleTextureSuffix
        do
            if quality < 2 then
                bubbleDensity = 30
                bubbleTextureSuffix = "Low"
            elseif quality < 3 then
                bubbleDensity = 30
                bubbleTextureSuffix = "Med"
            elseif quality < 4 then
                bubbleDensity = 40
                bubbleTextureSuffix = "High"
            else
                bubbleDensity = 50
                bubbleTextureSuffix = "Ultra"
            end

            bubbleTexture = "textures/scene/Dust" .. bubbleTextureSuffix .. ".png"
        end

        -- Air bubble model
        do
            local bubbleMesh =
                BuildMesh {
                mesh = "models/background/airbubble.obj",
                barycentricTangents = true,
                calculateNormals = false,
                submeshesWhenCombining = false
            }

            CreateObject {
                name = "AirBubbles",
                visible = false,
                tracknode = "start",
                gameobject = {
                    transform = {pos = {0, 0, 0}, scale = {0.55, 0.55, 0.55}},
                    mesh = bubbleMesh,
                    shader = "VertexColorUnlitTintedAlpha2",
                    shadercolors = {
                        --_Color = "highway"
                        _Color = {150, 150, 150}
                    },
                    texture = bubbleTexture,
                    layer = 13,
                }
            }
        end

        -- Air bubble scattering
        do
            -- Bubble placements
            if bubbleNodes == nil and bubbleNodesTop == nil then
                local bubbleNodes = {}
                local bubbleNodesTop = {}

                offsets = {}
                offsetsTop = {}
                for i = 1, #track do
                    -- This portion scatters bubbles BESIDE the track
                    if i % 4 == 0 and track[i].funkyrot == false then
                        bubbleNodes[#bubbleNodes + 1] = i

                        local xOffset = trackWidth + math.random(10, 100) -- Add track width so it doesn't appear on or near the track
                        local yOffset = math.random(-50, 50)

                        --Randomize rather the bubble appear left or right of the track
                        if math.random(0, 1) > 0.4 then
                            xOffset = xOffset * -1
                        end

                        offsets[#offsets + 1] = {xOffset,yOffset, 0}
                    end

                    -- This portion scatters bubbles ON TOP of the track
                    if i % 15 == 0 and track[i].funkyrot == false then
                        bubbleNodesTop[#bubbleNodesTop + 1] = i

                        local xOffsetTop = trackWidth + math.random(-20, 20)
                        local yOffsetTop = trackWidth + math.random(10, 50)

                        offsetsTop[#offsetsTop + 1] = {xOffsetTop,yOffsetTop, 0}
                    end
                end

                --Tell the game to render the model (prefab) in a batch (with Graphics.DrawMesh) every frame
                BatchRenderEveryFrame {
                    prefabName = "AirBubbles",
                    locations = bubbleNodes, -- Render bubbles beisdes the track
                    rotateWithTrack = true,
                    maxShown = bubbleDensity,
                    maxDistanceShown = 800,
                    offsets = offsets,
                    collisionLayer = -7, --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = false
                }
                BatchRenderEveryFrame {
                    prefabName = "AirBubbles",
                    locations = bubbleNodesTop, -- Render bubbles on top of the track
                    rotateWithTrack = true,
                    maxShown = bubbleDensity,
                    maxDistanceShown = 800,
                    offsets = offsetsTop,
                    collisionLayer = -7,
                        --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                    testAndHideIfCollideWithTrack = false
                }
            end
        end
    end
end --end of air bubbles


--------------------------------------------------------------------------------

-- Waves (wakeboard mode only)

--------------------------------------------------------------------------------
do --Waves
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


--------------------------------------------------------------------------------

-- Background objects

--------------------------------------------------------------------------------
do --Background objects
    if showBackgroundBuilding then
        if quality >= 3 then -- Only show objects on 'high' graphic setting

            --Disks
            do
                --Disk model
                do
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
                            transform = {scale = {scaletype = "intensity", min = {30, 135, 30}, max = {135, 135, 135}}},
                            texture = "textures/rail/cliff side.png",
                            layer = 19
                        }
                    }
                end

                --Disk poll model
                do
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
                                --_Color = "highway"
                                _Color = { r=101, g=101, b=101 }
                            },
                            transform = {scale = {68, 68, 68}},
                            texture = "textures/rail/cliff side.png",
                            layer = 19
                        }
                    }
                end

                --Model placement & render
                if buildingNodes == nil then
                    local buildingRotatAnimation = {}
                    local buildingNodes = {}
                    offsets = {}

                    for i = 1, #track do
                        if i % 80 == 0 then
                            buildingNodes[#buildingNodes + 1] = i
                            buildingRotatAnimation[#buildingRotatAnimation + 1] = {0, 0, 0}

                            --Offset from origin
                            local xOffset = math.random(450, 600)
                            local yOffset = math.random(0, 1)
                            local zOffset = math.random(-1, 0)
                            -- if xOffset < 300 then
                            --     xOffset = 670
                            -- end

                            --Randomize rather the building appear left or right of the track
                            if math.random() > 0.4 then
                                xOffset = xOffset * -1
                            end

                            --Building offset on {x,y,z}
                            offsets[#offsets + 1] = {xOffset, yOffset, zOffset}
                        end
                    end

                    --Tell the game to render the model (prefab) in a batch (with Graphics.DrawMesh) every frame
                    BatchRenderEveryFrame {
                        prefabName = "Disks",
                        locations = buildingNodes,
                        rotateWithTrack = false,
                        rotationspeeds = buildingRotatAnimation,
                        maxShown = 8,
                        maxDistanceShown = 600,
                        offsets = offsets,
                        collisionLayer = -4, --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                        testAndHideIfCollideWithTrack = true --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                    }

                    --Tell the game to render the model (prefab) in a batch (with Graphics.DrawMesh) every frame
                    BatchRenderEveryFrame {
                        prefabName = "DisksPole",
                        locations = buildingNodes,
                        rotateWithTrack = false,
                        rotationspeeds = buildingRotatAnimation,
                        maxShown = 8,
                        maxDistanceShown = 600,
                        offsets = offsets,
                        collisionLayer = -4, --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                        testAndHideIfCollideWithTrack = true --if true, it checks each render location against a ray down the center of the track for collision. Any hits are not rendered
                    }
                end
            end

            --That dart like thingy I don't know what to call it
            do
                --Adjust texture quality base on graphic setting
                if quality < 4 then
                    clingTexture = "textures/backgroundBuildings/flydart/ClingderShader_High.png"
                else
                    clingTexture = "textures/backgroundBuildings/flydart/ClingderShader_Ultra.png"
                end

                --Model
                do
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
                            transform = {pos = {0, 0, 0}, scale = {1.5, 1.5, 1.5}},
                            mesh = buildingMesh4,
                            shader = "IlluminDiffuse",
                            texture = clingTexture,
                            layer = 13,
                            shadercolors = {
                                _Color = "highway"
                            }
                        }
                    }
                end

                --Model placement & render
                if buildingNodes3 == nil then
                    local buildingNodes3 = {}
                    local buildingRotateAnimation = {}
                    offsets = {}
                    for i = 1, #track do
                        if i % 1200 == 0 and track[i].funkyrot == false and song < 0.83 then
                            buildingNodes3[#buildingNodes3 + 1] = i
                            buildingRotateAnimation[#buildingRotateAnimation + 1] = {0, 370, 0}

                            --Offset from origin
                            local xOffset = 80

                            --Randomize rather the building appear left or right of the track
                            if math.random(0, 1) > 0.4 then
                                xOffset = xOffset * -1
                            end

                            --Building offset on {x,y,z}
                            offsets[#offsets + 1] = {xOffset, 2, 0}
                        end
                    end

                    --Tell the game to render the model (prefab) in a batch (with Graphics.DrawMesh) every frame
                    BatchRenderEveryFrame {
                        prefabName = "FlyingThing",
                        locations = buildingNodes3,
                        rotateWithTrack = true,
                        rotationspeeds = buildingRotateAnimation,
                        maxShown = 5,
                        maxDistanceShown = 2000,
                        offsets = offsets,
                        collisionLayer = -7, --will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                        testAndHideIfCollideWithTrack = false
                    }
                end
            end

            --Disco ball
            do
                --Adjust texture quality base on graphic setting
                if quality < 4 then
                    clingTexture = "textures/backgroundBuildings/disco/Discoball_solid_High.png"
                else
                    clingTexture = "textures/backgroundBuildings/disco/Discoball_solid_Ultra.png"
                end

                --Model
                do
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
                            transform = {pos = {0, 0, 0}, scale = {105, 105, 105}},
                            mesh = buildingMesh5,
                            shader = "IlluminDiffuse",
                            texture = clingTexture,
                            layer = 13,
                            shadercolors = {
                                _Color = "highway"
                            }
                        }
                    }
                end

                --Model placement & render
                if buildingNodes5 == nil then
                    local buildingNodes5 = {}
                    offsets = {}

                    for i = 1, #track do
                        if i % 1750 == 0 and not track[i].funkyrot and song < 0.84 then
                            buildingNodes5[#buildingNodes5 + 1] = i

                            --Offset from origin
                            local xOffset = 356

                            --Randomize rather the building appear left or right of the track
                            if math.random(0, 1) > 0.5 then
                                xOffset = xOffset * -1
                            end

                            --Building offset on {x,y,z}
                            offsets[#offsets + 1] = {xOffset, 50, 0}
                        end
                    end

                    --Tell the game to render the model (prefab) in a batch (with Graphics.DrawMesh) every frame
                    BatchRenderEveryFrame {
                        prefabName = "Discoball",
                        locations = buildingNodes5,
                        rotateWithTrack = true,
                        maxShown = 5,
                        maxDistanceShown = 2000,
                        offsets = offsets,
                        collisionLayer = -2, --Will collision test with other batch-rendered objects on the same layer. set less than 0 for no other-object collision testing
                        testAndHideIfCollideWithTrack = true
                    }
                end
            end

            --Dancing Blocks
            do
                --Adjust texture quality base on graphic setting
                if quality < 4 then
                    clingTexture = "textures/backgroundBuildings/blockDance/BlockDance_High.png"
                else
                    clingTexture = "textures/backgroundBuildings/blockDance/BlockDance_Ultra.png"
                end

                --Model
                do
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
                end

                --Model placement & render
                if buildingNodes6 == nil then
                    local buildingNodes6 = {}
                    local buildingRotateAnimation = {}
                    offsets = {}

                    for i = 1, #track do
                        if (i % 2310) == 0 and not track[i].funkyrot and song < 0.83 then
                            buildingNodes6[#buildingNodes6 + 1] = i
                            buildingRotateAnimation[#buildingRotateAnimation + 1] = {0, 200, 0}

                            --Offset from origin
                            local xOffset = 330

                            --Randomize rather the building appear left or right of the track
                            if math.random(0, 1) > 0.5 then
                                xOffset = xOffset * -1
                            end

                            --Building offset on {x,y,z}
                            offsets[#offsets + 1] = {xOffset, 0, 0}
                        end
                    end

                    --Tell the game to render the model (prefab) in a batch (with Graphics.DrawMesh) every frame
                    BatchRenderEveryFrame {
                        prefabName = "BlockDance",
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
            end

        end --endif quality >= 3
    end --endif showBackgroundBuilding

end --End of background objects


--------------------------------------------------------------------------------

-- End of track object (Also known as endcookie)

--------------------------------------------------------------------------------
do --End of track object

    -- Adjust texture quality base on graphic setting
    if quality < 2 then
        portalTexture = "textures/end/Portal_Low.png"
    elseif quality < 3 then
        portalTexture = "textures/end/Portal_Med.png"
    elseif quality < 4 then
        portalTexture = "textures/end/Portal_High.png"
    else
        portalTexture = "textures/end/Portal_Ultra.png"
    end

    -- Change endcookie layer for 'low' graphic setting (background layer is disabled on 'low')
    if quality < 2 then
        endLayer = 13
    else
        endLayer = 19
    end

    -- Models
    do
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
    end

    -- Placement & render
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

        -- Renders the objects
        BatchRenderEveryFrame {
            prefabName = "EndCookie_TentInner",
            locations = endCookieNode, -- Place only one at the end of track, same logic goes to all renders below
            rotateWithTrack = true,
            rotationspeeds = buildingRotatAnimation,
            maxShown = 1,
            maxDistanceShown = 100000,
            offsets = offsets,
            collisionLayer = -1,
            testAndHideIfCollideWithTrack = false
        }
        BatchRenderEveryFrame {
            prefabName = "EndCookie_TentOuter",
            locations = endCookieNode,
            rotateWithTrack = true,
            rotationspeeds = buildingRotatAnimation,
            maxShown = 1,
            maxDistanceShown = 100000,
            offsets = offsets,
            collisionLayer = -1,
            testAndHideIfCollideWithTrack = false
        }
        BatchRenderEveryFrame {
            prefabName = "EndCookie_portal",
            locations = endCookieNode,
            rotateWithTrack = true,
            rotationspeeds = buildingRotatAnimation2,
            maxShown = 1,
            maxDistanceShown = 100000,
            offsets = offsets,
            collisionLayer = -1,
            testAndHideIfCollideWithTrack = false
        }
    end
end --End of end object


--------------------------------------------------------------------------------

-- Rails
-- (rails are the bulk of the graphics in audiosurf. Each one is a 2D shape extruded down the length of the track.)

--------------------------------------------------------------------------------

--        Left rail upperleft outline O-------------------O Left rail upperright outline         	   Right rail upperleft outline	O-------------------O Right rail upperright outline
--        							  |                   |                  														|                   |
--        							  |                   |                  														|                   |
--        							  |                   | Left rail bottomright outline             Right rail bottomleft outline |                   |
--        							  |                   O                  														O                   |
--        							  |    (Left guard)   | ----------------------------------------------------------------------- |    (Right guard)  |
--        							  |                   |                  			(Road surface)							    |                   |
--        							  |                   |                  														|                   |
--        							  |                   |                  														|                   |
--        							  |                   |                  														|                   |
--       Left rail bottomleft outline O--------------------                                                                         --------------------O Right rail bottomright outline

----------------------
-- Road surface
----------------------
do --Road surface
    if not wakeboard then
        CreateRail {
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
            color = {r = 251, g = 251, b = 251, a = 240},
            renderqueue = 2001,
			fullfuture = showEntireRoad,
            flatten = false,
            shader = "VertexColorUnlitTintedAlpha"
        }
    end
end --End of road surface

----------------------
-- Guard rails
----------------------
do --Guard rails
    local shaderName = "DiffuseVertexColored2"
    local shaderColor = { _Color = "highway", a = 50 }
    local railLayer = 13
    local renderQueue = 1999

    -- Left guard
    CreateRail {
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
        renderqueue = renderQueue,
        fullfuture = showEntireRoad,
        shadowcaster = false,
        shadowreceiver = true,
        calculatenormals = false,
        shader = shaderName,
        shadercolors = shaderColor,
        layer = railLayer
    }

    -- Right guard
    CreateRail {
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
        renderqueue = renderQueue,
        shadowcaster = false,
        shadowreceiver = true,
        calculatenormals = false,
        shader = shaderName,
        shadercolors = shaderColor,
        layer = railLayer
    }

end --End of guard rails

----------------------
-- Rail outlines
----------------------
do --Rail outlines
    local outlineColor = {r = 101, g = 101, b = 101}
    local shaderName = "DiffuseVertexColored2"
    local shaderColor = { _Color = {r = 0, g = 0, b = 0} }
    local railLayer = 13

    --Left
    if not wakeboard then
        --Left rail upperleft outline
        CreateRail {
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
            color = outlineColor,
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = shaderName,
            shadercolors = shaderColor,
            layer = railLayer
        }

        --Left rail bottomright outline
        CreateRail {
            positionOffset = {
                x = -trackWidth + 0.11,
                y = 0
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
            color = outlineColor,
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = shaderName,
            shadercolors = shaderColor,
            layer = railLayer
        }

        --Left rail upperright outline
        CreateRail {

            positionOffset = {
                x = -trackWidth - 0.84,
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
            color = outlineColor,
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = shaderName,
            shadercolors = shaderColor,
            layer = railLayer
        }
    end

    --Right
    if not wakeboard then
        --Right rail upperleft outline
        CreateRail {

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
            color = outlineColor,
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = shaderName,
            shadercolors = shaderColor,
            layer = railLayer
        }

        --Right rail upperright outline
        CreateRail {

            positionOffset = {
                x = trackWidth + 0.51,
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
            color = outlineColor,
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = shaderName,
            shadercolors = shaderColor,
            layer = railLayer
        }

        --Right rail bottomleft outline
        CreateRail {

            positionOffset = {
                x = trackWidth - 0.445,
                y = 0
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
            color = outlineColor,
            flatten = false,
            fullfuture = showEntireRoad,
            shadowcaster = false,
            shadowreceiver = false,
            calculatenormals = true,
            shader = shaderName,
            shadercolors = shaderColor,
            layer = railLayer
        }
    end

end --End of rail outline

----------------------
-- Lane divider
----------------------

--                         o                     o
-- -----------------------------------------------------------------------
--                             (Road surface)
--
-- 'o' denotes lane divider positions

do --Lane divier
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
end --End of lane divider

----------------------
-- Shoulder lanes
----------------------

-- Casual:
--                        o                                                                 o
--      ****************-----------------------------------------------------------------------****************-
--                                                     (Road surface)
--
--      'o' denotes shoulder lane line positions
--      '****' denotes shoulder roads


-- Mono/Ninja:
--        o                                                                 o
--      -----------------------------------------------------------------------
--                                  (Road surface)
--
--      'o' denotes shoulder lane line positions

do --Shoulder lanes
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
end --End of shoulder lanes

----------------------
-- Rail rim lights
----------------------

--            <------------ Left rail ouward light                            Right rail ouward light  ------------>
--      ---------------------                                                                         ---------------------
--      |                   | |                 													| |                   |
--      |                   | | Left rail light                 				   Right rail light | |                   |
--      |                   | V                                                                     V |                   |
--      |                   |                 														  |                   |
--      |    (Left guard)   | ----------------------------------------------------------------------- |    (Right guard)  |
--      |                   |                  			(Road surface)							      |                   |
--      |                   | ^                 												    ^ |                   |
--      |                   | | Left rail reflection light              Right rail reflection light | |                   |
--      |                   | |                 													| |                   |
--      --------------------                                                                          ---------------------

do --Rail rim lights
    if not wakeboard then

        --Left
        do
            --Left rail light
            CreateRail {
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

            --Left rail outward light
            CreateRail {
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

            --Left rail reflection light
            CreateRail {
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
        end

        --Right
        do
            --Right rail light
            CreateRail {
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

            --Right rail outward light
            CreateRail {
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

            --Right rail reflection light
            CreateRail {
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

        end

    end
end --End of rail rim lights

----------------------
-- Rail cliff
----------------------

--                 Left rail O______________O Right rail
--							  (Road surface)

--                  (Left cliff top)   (Right cliff top)
--						  ---------------------
--	      (Left cliff)	/						\ (Right cliff)
--					/								\
--				X (Cliff outline LT) (Cliff outline RT) X
--			/												\
--		   |												 |
--		   | (Left side cliff)			   (Right side cliff)|
--		   |												 |
--		   X (Cliff outline LB)			  (Cliff outline RB) X
--		   |												 |

do --Rail cliff
    if not wakeboard then
        local outlineColor = {r = 101, g = 101, b = 101};

        --Left
        do
            --Left cliff
            CreateRail {
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
                colorMode = oneColorCliff and "static" or "highway",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/big cliff.png",
                fullfuture = true,
                stretch = math.ceil(#track * 3 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = oneColorCliff and {_Color = "highway"} or nil,
                layer = 13
            }

            --Left side cliff
            CreateRail {

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
                colorMode = oneColorCliff and "static" or "highway",
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
                shadercolors = oneColorCliff and {_Color = "highway"} or nil,
                layer = 13
            }

            --Left cliff top
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
                colorMode = oneColorCliff and "static" or "highway",
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
                shadercolors = oneColorCliff and {_Color = "highway"} or nil,
                layer = 13
            }

            --Cliff outline LB
            CreateRail {
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
                color = outlineColor,
                flatten = false,
                fullfuture = false,
                shadowcaster = false,
                shadowreceiver = true,
                calculatenormals = false,
                shader = "DiffuseVertexColored2",
                shadercolors = {55, 55, 55},
                layer = 13
            }

            --Cliff outline LT
            CreateRail {
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
                color = outlineColor,
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

        --Right
        do
            --Right cliff
            CreateRail {
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
                colorMode = oneColorCliff and "static" or "highway",
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
                shadercolors = oneColorCliff and {_Color = "highway"} or nil,
                layer = 13
            }

            --Right side cliff
            CreateRail {

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
                colorMode = oneColorCliff and "static" or "highway",
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
                shadercolors = oneColorCliff and {_Color = "highway"} or nil,
                layer = 13
            }

            --Right cliff top
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
                colorMode = oneColorCliff and "static" or "highway",
                color = {r = 255, g = 255, b = 255},
                flatten = false,
                wrapnodeshape = false,
                texture = "textures/rail/cliff side2.png",
                fullfuture = true,
                stretch = math.ceil(#track * 2 / 63500),
                calculatenormals = false,
                allowfullmaterialoptions = false,
                shader = "VertexColorUnlitTintedAlpha2",
                shadercolors = oneColorCliff and {_Color = "highway"} or nil,
                layer = 13
            }

            -- Cliff outline RB
            CreateRail {
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
            color = outlineColor,
            flatten = false,
            fullfuture = false,
            shadowcaster = false,
            shadowreceiver = true,
            calculatenormals = false,
            shader = "DiffuseVertexColored2",
            shadercolors = {55, 55, 55},
            layer = 13
        }

        --Cliff outline RT
        CreateRail {
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
            color = outlineColor,
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
    end
end

----------------------
-- Rail cliff (wakeboard)
----------------------

--					      O
--			       ......-|- ......
--			^......	      /\	   .....^
--			   ~~~~~~~~~~~~~~~~~~~~~~~~
--          /                          \
--         /                            \
--       */                              \*
--       /                                \
--
--  '*' Denotes cliff outlines
-- '/' and '\' denotes cliff (one giant rail, so no left and right differenciation)

do --Wakeboard cliff
    if wakeboard then
        --Cliff
        CreateRail {
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
            colorMode = oneColorCliff and "static" or "highway",
            color = {r = 255, g = 255, b = 255},
            flatten = false,
            wrapnodeshape = true,
            texture = "textures/rail/big cliff.png",
            fullfuture = true,
            stretch = math.ceil(#track * 6 / 63500),
            calculatenormals = false,
            allowfullmaterialoptions = false,
            shader = "VertexColorUnlitTintedAlpha2",
            shadercolors = oneColorCliff and {_Color = "highway"} or nil,
            layer = 13
        }

        --Left cliff outline
        CreateRail {
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

        --Right cliff outline
        CreateRail {
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
end --End of wakeboard cliff

----------------------
-- Skyline (wakeboard)
----------------------

-- 		O (left skyline)    (right skyline) O
--
--
--					      O
--			       ......-|- ......
--			^......	      /\	   .....^
--			   ~~~~~~~~~~~~~~~~~~~~~~~~

do --Wakeboard skyline
    if wakeboard then
        --left skyline
        CreateRail {
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
            texture = "textures/rail/big cliff.png",
            shader = "VertexColorUnlitTintedAlpha2"
        }

        --right skyline
        CreateRail {
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
            texture = "textures/rail/big cliff.png",
            shader = "VertexColorUnlitTintedAlpha2"
        }

    end
end --End of skyline
