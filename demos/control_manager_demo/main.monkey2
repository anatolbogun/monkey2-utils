#Import "<std>"
#Import "<mojo>"
#Import "<pyro-framework>"
#Import "<pyro-scenegraph>"

#Import "../../assets/"

#Import "../../src/accelerometer"
#Import "../../src/control_manager"

Using std..
Using mojo..
Using pyro.framework..
Using pyro.scenegraph..

Global VirtualResolution := New Vec2i


Function Main()
	
	New AppInstance
 	
	VirtualResolution.x = 720
	VirtualResolution.y = 1280
	
	New ControlManagerDemoApp( "Accelerometer Demo", VirtualResolution.x, VirtualResolution.y )
	
	App.Run()
End


Class ControlManagerDemoApp Extends Window
	
	Field Scene:Scene
	Field Camera:Camera
	Field Arrow:LayerSprite
	Field ControlManager:ControlManager
	Field Accel:Accelerometer
	
	Const DegreesPerKeyDown := 1
	Const RadiansPerKeyDown := DegreesPerKeyDown * Pi / 180
	
	Method New( name:String, width:Int, height:Int, flags:WindowFlags = WindowFlags.Resizable )
		Super.New( name, width, height, flags )
		
		ClearColor = Color.Black
		Layout = "letterbox"
		
		Scene = New Scene( Self )
		Camera = New Camera( Scene )
		Accel = New Accelerometer()
		Local layer := New Layer( Scene )
		
		Arrow = New LayerSprite( layer, Content.GetImage( "asset::arrow.png" ) )
		Arrow.X = width / 2
		Arrow.Y = height / 2
		
		AddControls()
	End
		
	Method AddControls()
		'  Creating a new ControlManager instance.
		ControlManager = New ControlManager()
				
		If Accel.Supported
			' Accelerometer controls
			
			' create a condition that will trigger a function call (callback function passed to the ControlManager)
			Local unconditional := Lambda:Bool ()
				Return True
			End
			
			' create the callback function (action to be taken when the above condition is met)
			Local rotateArrowByAccel := Lambda ()
				Arrow.Rotation = -Accel.Y
			End
			
			' add both condition and callback function to the ControlManager and give it a key (e.g. "accelerometer")
			' so that we can later access this control type, e.g. to disable it via ControlManager.disable( "accelerometer" ).
			ControlManager.Add( "accelerometer", unconditional, rotateArrowByAccel )
			
			' more controls below:
			Local fingerDown := Lambda:Bool ()
				Return Touch.FingerPressed( 0 )
			End
			
			Local calibrateAccelerometer := Lambda ()
				If Accel.CenterX <> 0
					Accel.ResetCalibrate()
				Else
					Accel.Calibrate()
				End
			End
			
			ControlManager.Add( "fingerDown", fingerDown, calibrateAccelerometer )
		Else
			' Keyboard controls
			
			Print( "This device does not provide accelerometer data." )
			
			' even more controls, just to demonstrate how flexible the ControlManager is
			Local leftArrowKeyDown := Lambda:Bool ()
				Return Keyboard.KeyDown( Key.Left )			
			End
			
			Local rightArrowKeyDown := Lambda:Bool ()
				Return Keyboard.KeyDown( Key.Right )			
			End
			
			Local arrowRotateLeft := Lambda ()
				Arrow.Rotation -= RadiansPerKeyDown
			End
			
			Local arrowRotateRight := Lambda ()
				Arrow.Rotation += RadiansPerKeyDown
			End
			
			ControlManager.Add( "leftArrowKeyDown", leftArrowKeyDown, arrowRotateLeft )
			ControlManager.Add( "rightArrowKeyDown", rightArrowKeyDown, arrowRotateRight )
		End
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
		
		Accel.OnUpdate()
		
		' all you have to do now is to call ControlManager.OnUpdate() on every OnRender loop
		ControlManager.OnUpdate()
		
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