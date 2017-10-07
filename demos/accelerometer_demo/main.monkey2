#Import "<std>"
#Import "<mojo>"
#Import "<pyro-framework>"
#Import "<pyro-scenegraph>"

#Import "../../assets/"

#Import "../../src/accelerometer"

Using std..
Using mojo..
Using pyro.framework..
Using pyro.scenegraph..

Global VirtualResolution := New Vec2i


Function Main()
	
	New AppInstance
 	
	VirtualResolution.x = 720
	VirtualResolution.y = 1280
	
	New AccelerometerDemoApp( "Accelerometer Demo", VirtualResolution.x, VirtualResolution.y )
	
	App.Run()
End


Class AccelerometerDemoApp Extends Window
	
	Field Scene:Scene
	Field Camera:Camera
	Field Arrow:LayerSprite
	Field Accel:Accelerometer
	
	Const DegreesPerKeyDown := 1
	Const RadiansPerKeyDown := DegreesPerKeyDown * Pi / 180
	
	Method New( name:String, width:Int, height:Int, flags:WindowFlags = WindowFlags.Resizable )
		Super.New( name, width, height, flags )
		
		ClearColor = Color.Black
		Layout = "letterbox"
		
		Scene = New Scene( Self )
		Camera = New Camera( Scene )
		
		' Creating an Accelerometer instance
		Accel = New Accelerometer()
		
		Local layer := New Layer( Scene )
		
		Arrow = New LayerSprite( layer, Content.GetImage( "asset::arrow.png" ) )
		Arrow.X = width / 2
		Arrow.Y = height / 2
	End
	
	Method RadiansToDegrees:Float ( radians:Float )
		Return radians * 180 / Pi
	End
	
	Method DegreesToRadians:Float ( degrees:Float )
		Return degrees * Pi / 180
	End
	
	Method OnRender:Void( canvas:Canvas ) Override
		App.RequestRender()
		Scene.Update()
		Scene.Draw( canvas )
		
		' All you need to do is to call Accel.OnUpdate on every OnRender
		Accel.OnUpdate()
		
		' Then just use any of the Accel Properties.
		' For device rotation use Accel.X / Y / Z in radians in the range -Pi to Pi
		' or the normalised values NormalX / NormalY / NormalZ in the range -1.0 to 1.0.
		Arrow.Rotation = -Accel.Y
		
		' Try this to use some normalised values and apply them to the sprite scale:
		' Arrow.ScaleX = Abs( Accel.NormalZ ) + 0.5 / 1.5
		' Arrow.ScaleY = Abs( Accel.NormalZ ) + 0.5 / 1.5
		
		' For testing purposes touch the screen to calibrate the accelerometer to the
		' current device gravitational centre (the current device orientation is the 0 point for X, Y and Z).
		' Touch again to reset the calibration.
		If ( Touch.FingerPressed( 0 ) )
			If Accel.CenterX <> 0
				Accel.ResetCalibrate()
			Else
				Accel.Calibrate()
			End
		End
		
		canvas.DrawText( "Accelerometer Data", 100, 100 )

		canvas.DrawText( "GX: " + Accel.GX, 100, 160 )
		canvas.DrawText( "GY: " + Accel.GY, 100, 190 )
		canvas.DrawText( "GZ: " + Accel.GZ, 100, 220 )
		
		canvas.DrawText( "X rad: " + Accel.X + ", deg: " + RadiansToDegrees( Accel.X ), 500, 160 )
		canvas.DrawText( "Y rad: " + Accel.Y + ", deg: " + RadiansToDegrees( Accel.Y ), 500, 190 )
		canvas.DrawText( "Z rad: " + Accel.Z + ", deg: " + RadiansToDegrees( Accel.Z ), 500, 220 )
		
		canvas.DrawText( "(Touch the screen to calibrate / reset calibration of the accelerometer.)", 100, 280 )
	End
	
	Method OnMeasure:Vec2i() Override
		Return VirtualResolution
	End
	
End