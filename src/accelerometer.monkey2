#Import  "low_pass_filter"


Class Accelerometer
	
	' X, Y, Z are the device rotation in radians on the respective axes, in the range -Pi to Pi.
	' If set the low pass filter is applied to these values.
	Field X:Float
	Field Y:Float
	Field Z:Float
	
	' RawX, RawY, RawZ is the raw and unaltered accelerometer data. No filter is applied.
	Field RawX:Float
	Field RawY:Float
	Field RawZ:Float
	
	' GX, GY, GZ is the G (force) value in the range -1.0 to 1.0.
	' If set the low pass filter is applied to these values.
	' This value is simply a raw value multiplied by the device multiplier so that it matches the -1.0 to 1.0 range.
	Field GX:Float
	Field GY:Float
	Field GZ:Float
	
	' CenterX, CenterY, CenterZ are the gravitational center offsets for calibration.
	' The default of all values is 0. The possible range is -Pi to Pi.
	' There are two ways to calibrate this accelerometer:
	' 1. by calling Calibrate() which will set the gravitational centre to the current device rotation.
	' 2. by setting CenterX , CenterY, CenterZ manually (could be useful if the app allows device orientation changes).
	Field CenterX:Float
	Field CenterY:Float
	Field CenterZ:Float
	
	' Supported is True if an Accelerometer can be found for this device.
	Field Supported:Bool
	
	' Creates an Accelerometer instance for easy access to the current device rotation values.
	' useLowPassFilter: filters out any spikes that come from the raw data which can lead to jittery results
	' dt: low pass filter time interval
	' rc: low pass filter time constant
	' deviceMultiplier: iOS seems to produce raw data in the range -0.2 to 0.2, but we need values in the range -1.0 to 1.0
	' Note: The low pass filter will cause a slight delay of values which is the compromise for smoother results.
	'       Adjust dt and rc for different results, the smoother the more delay, the closer to the raw data the more jitter.
	#If __TARGET__ = "ios"
	Method New ( useLowPassFilter:Bool = True, dt:Float = 0.05, rc:Float = 0.3, deviceMultiplier:Float = 5 )
	#Else
	Method New ( useLowPassFilter:Bool = True, dt:Float = 0.05, rc:Float = 0.3, deviceMultiplier:Float = 1 )
	#Endif				
		_DeviceMultiplier = deviceMultiplier
		_Joystick = _GetAccelerometerJoystick()
		Supported = _Joystick <> Null
		
		If useLowPassFilter
			_LowPassFilterX = New LowPassFilter( 0, dt, rc )
			_LowPassFilterY = New LowPassFilter( 0, dt, rc )
			_LowPassFilterZ = New LowPassFilter( 0, dt, rc )
		End
	End
	
	' Normalises the X value to the range -1.0 to 1.0.
	' This is helpful if you want to use the device rotation to control something that is not a rotation, e.g. to change the z position in space.
	Property NormalX:Float ()
		Return X / Pi		
	End
	
	Property NormalY:Float ()
		Return Y / Pi		
	End
	
	Property NormalZ:Float ()
		Return Z / Pi		
	End
	
	' Sets the gravitational centre to the current device rotation.
	Method Calibrate ()
		CalibrateX()
		CalibrateY()
		CalibrateZ()		
	End
	
	Method CalibrateX ()
		CenterX = ATan2( GY, GZ )
	End
	
	Method CalibrateY ()
		CenterY = ATan2( GX, GY )
	End
	
	Method CalibrateZ ()
		CenterZ	= ATan2( GZ, GY )
	End
	
	' Resets the gravitational centre to the default device centre.
	Method ResetCalibrate ()
		CenterX = 0
		CenterY = 0
		CenterZ = 0		
	End
	
	' Call this in every OnRender loop.
	Method OnUpdate ()
		If Not _Joystick Then Return
		
		RawX = _Joystick.GetAxis( 0 )
		RawY = _Joystick.GetAxis( 1 )
		RawZ = _Joystick.GetAxis( 2 )
		
		GX = RawX * _DeviceMultiplier
		GY = RawY * _DeviceMultiplier
		GZ = RawZ * _DeviceMultiplier
		
		If _LowPassFilterX
			' The following explanation is clearer in degrees, so a G value of -1 results in -180 degrees, +1 results in 180 degrees.
			' For the low pass filter we need to avoid the scenario that the value jumps by about 360 degrees.
			' Instead we calculate the difference of previous and current value and update the lowpass filter value accordingly.
			' E.g. if on consecutive frames the value is -179 and then +179 we change the lowpass filter value to +181,
			' otherwise the filter would calculate a quickly tweened 358 degree clockwise rotation
			' which actually is a counter clockwise rotation of only 2 degrees.
			' We assume for this case that a device rotation of more than 180 degrees (G value difference > 1)
			' cannot be done within one frame, so a difference of > 180 degrees will trigger the adjustment.
			Local diffX := GX - _LowPassFilterX.Value
			Local diffY := GY - _LowPassFilterY.Value
			Local diffZ := GZ - _LowPassFilterZ.Value
			
			If Abs( diffX ) > 1 Then _LowPassFilterX.Value = GX + Sgn( diffX ) * ( 2 - Abs( diffX ) )
			If Abs( diffY ) > 1 Then _LowPassFilterY.Value = GY + Sgn( diffY ) * ( 2 - Abs( diffY ) )
			If Abs( diffZ ) > 1 Then _LowPassFilterZ.Value = GZ + Sgn( diffZ ) * ( 2 - Abs( diffZ ) )
			
			GX = _LowPassFilterX.OnUpdate( GX )
			GY = _LowPassFilterY.OnUpdate( GY )
			GZ = _LowPassFilterZ.OnUpdate( GZ )
		End
		
		' Let's turn the G (force) values into radians.
		X = ATan2( GY, GZ ) - CenterX
		Y = ATan2( GX, GY ) - CenterY
		Z = ATan2( GZ, GY ) - CenterZ
		
		' For calibrated values where CenterX/Y/Z is not 0 we need to ensure that X, Y and Z stay within the range -Pi to Pi.
		If Not ( -Pi <= X <= Pi ) Then X = -Sgn( X ) + X Mod Pi
		If Not ( -Pi <= Y <= Pi ) Then Y = -Sgn( Y ) + Y Mod Pi
		If Not ( -Pi <= Z <= Pi ) Then Z = -Sgn( Z ) + Z Mod Pi
	End
	
	
	Private
	
	Field _Joystick:JoystickDevice
	Field _DeviceMultiplier:Float
	Field _LowPassFilterX:LowPassFilter
	Field _LowPassFilterY:LowPassFilter
	Field _LowPassFilterZ:LowPassFilter
	
	' Check if the device has an accelerometer and return the joystick or Null.
	Method _GetAccelerometerJoystick:JoystickDevice ()
		For Local i := 0 Until JoystickDevice.NumJoysticks()
			Local joystick := JoystickDevice.Open( i )
			
			If joystick.Name.ToLower().Contains( "accelerometer" )
				Return joystick
			End
		Next
		
		Return Null
	End
End
	