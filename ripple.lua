--@name Ripple release
--@author Neatro
--@shared

--######################
--#                    #
--#  Ripple by Neatro  #
--#                    #
--######################

-- Licensed under Attribution-NonCommercial 3.0 Unported (CC BY-NC 3.0)

-- Basically from license:
--   Do not use commercially.
--   Credit Neatro, if any part of code is used.
--   Link back to the original repository where you got the code from.
--   You must indicated the changes you have made.
--   You must release the derivative work under the same or compatible license.
--   No warranties of any possible kind or form are given, see below.

--[[
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
]]--

if CLIENT then
    
    li = {}
    liv = {}
    livector = {}
    
    mins, maxs = 1, 12 --edge size of water, dont change mins

    iterations = 4 --physics iteration
    fps = 40 --target FPS of mesh
    
    local width = 512 / count
    local count = ( maxs - mins + 1 )

    for a = mins, maxs do 
        li[ a ] = {}
        liv[ a ] = {}
        livector[ a ] = {}
        for b = mins, maxs do
        li[ a ][ b ] = 0
        liv[ a ][ b ] = 0
        livector[ a ][ b ] = Vector()
        end
    end 
    
    function sget( t, x, y )
        return t[ math.clamp( x, mins, maxs ) ][ math.clamp( y, mins, maxs ) ]
    end
    function sset( t, x, y, v )
        t[ math.clamp( x, mins, maxs ) ][ math.clamp( y, mins, maxs ) ] = v
    end
    
    mat = material.load( "debug/env_cubemap_model" )
    
    
    nextFrame = math.ceil( timer.curtime() * fps ) / fps
    
    function advanceFrame()
        nextFrame = math.ceil( timer.curtime() * fps ) / fps
    end
    
    function interpolateFromField( t, x, y )
        local oo = sget( t, math.floor( x ), math.floor( y ) )
        local oi = sget( t, math.floor( x ), math.ceil( y ) )
        local io = sget( t, math.ceil( x ), math.floor( y ) )
        local ii = sget( t, math.ceil( x ), math.ceil( y ) )
        
        local xi = x % 1
        local yi = y % 1
        
        local oooi = oo * ( 1 - yi ) + oi * ( yi )
        local ioii = io * (1 -  yi ) + ii * ( yi )
        
        return oooi * ( 1 - xi ) + ioii * ( xi )
    end
    
    local rVector = Vector( 0, -1, 0 )
    
    hook.add( "render", "runtime", function() 
        local curx, cury = render.cursorPos()
        render.setBackgroundColor( Color( 0, 0, 0, 0 ) )
        
        if curx and player():keyDown( 32 ) then
            sset( liv, math.ceil( curx / width ), math.ceil( cury / width ), -256 )
            sset( liv, math.ceil( curx / width+1 ), math.ceil( cury / width ), -256 )
            sset( liv, math.ceil( curx / width ), math.ceil( cury / width+1 ), -256 )
            sset( liv, math.ceil( curx / width+1 ), math.ceil( cury / width+1 ), -256 )
        end
        
        if timer.curtime() > nextFrame then
            for i = 1, iterations do
                local avg = 0
                
                for i = mins, maxs do 
                    local livcol = liv[ i ]
                    local licol = li[ i ]
                    for j = mins, maxs do
                        local livcolval = livcol[ j ] * 0.99 - ( sget( li, i, j ) )
                            + ( ( sget( li, i + 1, j ) )
                            + ( sget( li, i - 1, j ) )
                            + ( sget( li, i, j + 1 ) )
                            + ( sget( li, i, j - 1 ) ) ) * 0.25
                        
                        livcol[ j ] = livcolval
                        
                        local result = licol[ j ] + livcolval * 0.02
                        
                        licol[ j ] = result
                        
                        avg = avg + result
                    end 
                end
                
                avg = avg / ( count * count )
                
                for i = mins, maxs do 
                    local licol = li[ i ]
                    local livectorcol = livector[ i ]
                    for j = mins, maxs do
                        licol[ j ] = licol[ j ] - avg
                        
                        local licolj = licol[ j ]
                        
                        livectorcol[ j ].x = sget( li, i - 1, j ) - licolj
                        livectorcol[ j ].y = sget( li, i, j - 1 ) - licolj
                                            
                    end 
                end
            end
                
            advanceFrame()
            
            if Me then
                Me:destroy()
                Me = nil
            end
            
            --the expensive part, meshing
            pcall( function()
                Me = mesh.createEmpty()
                         
                local chp = chip():getPos()
                
                render.setColor( Color( 255, 255, 255 ) )
                render.setMaterial( mat ) 
                
                mesh.generate( Me, 7, count * count, function() 
                    for i = mins, maxs do for j = mins, maxs do
                        local height1 = sget( li, i, j ) + 32
                        local height2 = sget( li, i+1, j ) + 32
                        local height3 = sget( li, i+1, j+1 ) + 32
                        local height4 = sget( li, i, j+1 ) + 32
                        
                        local normal1 = -( sget( livector, i, j ) + Vector( 0, 0, 32 ) ):getNormalized()
                        local normal2 = -( sget( livector, i+1, j ) + Vector( 0, 0, 32 ) ):getNormalized()
                        local normal3 = -( sget( livector, i+1, j+1 ) + Vector( 0, 0, 32 ) ):getNormalized()
                        local normal4 = -( sget( livector, i, j+1 ) + Vector( 0, 0, 32 ) ):getNormalized()
                        
                        local tangent1 = rVector:cross(normal1)
                        local tangent2 = rVector:cross(normal2)
                        local tangent3 = rVector:cross(normal3)
                        local tangent4 = rVector:cross(normal4)

                        mesh.writePosition( Vector( width * ( i - 1 ), width * ( j - 1 ), height1 ) )
                        mesh.writeUV( 0, ( i - 1 ) / maxs, ( j - 1 ) / maxs )
                        mesh.writeColor( 255, 255, 255, 255 )
                        mesh.writeNormal( normal1 )
                        mesh.writeUserData( tangent1.x, tangent1.y, tangent1.z, -1 )
                        mesh.advanceVertex()
                        
                        mesh.writePosition( Vector( width * ( i ), width * ( j - 1 ), height2 ) )
                        mesh.writeUV( 0, ( i ) / maxs, ( j - 1 ) / maxs )
                        mesh.writeColor( 255, 255, 255, 255 )
                        mesh.writeNormal( normal2 )
                        mesh.writeUserData( tangent2.x, tangent2.y, tangent2.z, -1 )
                        mesh.advanceVertex()
                        
                        mesh.writePosition( Vector( width * ( i ), width * ( j ), height3 ) )
                        mesh.writeUV( 0, ( i ) / maxs, ( j ) / maxs )
                        mesh.writeColor( 255, 255, 255, 255 )
                        mesh.writeNormal( normal3 )
                        mesh.writeUserData( tangent3.x, tangent3.y, tangent3.z, -1 )
                        mesh.advanceVertex()
                        
                        mesh.writePosition( Vector( width * ( i - 1 ), width * ( j ), height4 ) )
                        mesh.writeUV( 0, ( i - 1 ) / maxs, ( j ) / maxs )
                        mesh.writeColor( 255, 255, 255, 255 )
                        mesh.writeNormal( normal4 )
                        mesh.writeUserData( tangent4.x, tangent4.y, tangent4.z, -1 )
                        mesh.advanceVertex()
                        
                    end end
                end )
            end )
            
        end
        
        render.enableDepth( true )
        
        if Me then
            render.setMaterial( mat ) 
            render.setColor( Color( 255, 255, 255, 255 ) )
            Me:draw()
        end
        
        
    end )
    
end

if SERVER then
    local pcb = prop.createComponent( chip():getPos() + Vector( 0, 0, 32 ), Angle( 0, 0, 0 ), "starfall_screen", "models/hunter/plates/plate4x4.mdl", true )
    pcb:linkComponent( chip() )
    pcb:setColor( Color( 0, 0, 0, 1 ) )

end