Class LowPassFilter
	
	Field Value:Float
	Field Alpha:Float
	
	' dt : time interval
	' rc : time constant
	Method New ( startValue:Float = 0, dt:Float = 0.05, rc:Float = 0.3 )
		Value = startValue
		Alpha = dt / ( rc + dt )
	End
	
	Method OnUpdate:Float ( input:Float )
		Value = ( Alpha * input ) + ( 1.0 - Alpha ) * Value
		Return Value
	End
	
End