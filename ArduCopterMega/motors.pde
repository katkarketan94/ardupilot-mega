/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

#define ARM_DELAY 10
#define DISARM_DELAY 10

void arm_motors()
{
	static byte arming_counter;

	// Arm motor output : Throttle down and full yaw right for more than 2 seconds
	if (g.rc_3.control_in == 0){
		// full right
		if (g.rc_4.control_in > 4000) {
			if (arming_counter >= ARM_DELAY) {
				motor_armed 	= true;
				arming_counter 	= ARM_DELAY;

				// Remember Orientation
				// ---------------------------
				init_simple_bearing();

			} else{
				arming_counter++;
			}
		// full left
		}else if (g.rc_4.control_in < -4000) {
			if (arming_counter >= DISARM_DELAY){
				motor_armed 	= false;
				arming_counter 	= DISARM_DELAY;
			}else{
				arming_counter++;
			}
		// centered
		}else{
			arming_counter = 0;
		}
	}else{
		arming_counter = 0;
	}
}




/*****************************************
 * Set the flight control servos based on the current calculated values
 *****************************************/
void
set_servos_4()
{
	static byte num;
	int out_min;

	// Quadcopter mix
	if (motor_armed == true && motor_auto_safe == true) {
		out_min = g.rc_3.radio_min;

		// Throttle is 0 to 1000 only
		g.rc_3.servo_out 	= constrain(g.rc_3.servo_out, 0, 1000);

		if(g.rc_3.servo_out > 0)
			out_min = g.rc_3.radio_min + 90;

		//Serial.printf("out: %d %d %d %d\t\t", g.rc_1.servo_out, g.rc_2.servo_out, g.rc_3.servo_out, g.rc_4.servo_out);

		// creates the radio_out and pwm_out values
		g.rc_1.calc_pwm();
		g.rc_2.calc_pwm();
		g.rc_3.calc_pwm();
		g.rc_4.calc_pwm();

		// limit Yaw control so we don't clip and loose altitude
		// this is only a partial solution.

		// g.rc_4.pwm_out = min(g.rc_4.pwm_out, (g.rc_3.radio_out - out_min));

		//Serial.printf("out: %d %d %d %d\n", g.rc_1.radio_out, g.rc_2.radio_out, g.rc_3.radio_out, g.rc_4.radio_out);
		//Serial.printf("yaw: %d ", g.rc_4.radio_out);

		if(g.frame_type == PLUS_FRAME){
			//Serial.println("P_FRAME");
			motor_out[CH_1]		= g.rc_3.radio_out - g.rc_1.pwm_out;
			motor_out[CH_2]		= g.rc_3.radio_out + g.rc_1.pwm_out;
			motor_out[CH_3]		= g.rc_3.radio_out + g.rc_2.pwm_out;
			motor_out[CH_4] 	= g.rc_3.radio_out - g.rc_2.pwm_out;

			motor_out[CH_1]		+=  g.rc_4.pwm_out; 	// CCW
			motor_out[CH_2]		+=  g.rc_4.pwm_out; 	// CCW
			motor_out[CH_3]		-=  g.rc_4.pwm_out; 	// CW
			motor_out[CH_4] 	-=  g.rc_4.pwm_out; 	// CW

		}else if(g.frame_type == X_FRAME){
			//Serial.println("X_FRAME");
			int roll_out 	 	= g.rc_1.pwm_out * .707;
			int pitch_out 	 	= g.rc_2.pwm_out * .707;

			motor_out[CH_3]	 	= g.rc_3.radio_out + roll_out + pitch_out;
			motor_out[CH_2]	 	= g.rc_3.radio_out + roll_out - pitch_out;

			motor_out[CH_1]		= g.rc_3.radio_out - roll_out + pitch_out;
			motor_out[CH_4] 	= g.rc_3.radio_out - roll_out - pitch_out;

			//Serial.printf("\tb4: %d %d %d %d ", motor_out[CH_1], motor_out[CH_2], motor_out[CH_3], motor_out[CH_4]);

			motor_out[CH_1]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_2]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_3]		-= g.rc_4.pwm_out;	// CW
			motor_out[CH_4] 	-= g.rc_4.pwm_out;	// CW

			//Serial.printf("\tl8r: %d %d %d %d\n", motor_out[CH_1], motor_out[CH_2], motor_out[CH_3], motor_out[CH_4]);

		}else if(g.frame_type == TRI_FRAME){

			//Serial.println("TRI_FRAME");
			// Tri-copter power distribution

			int roll_out 		= (float)g.rc_1.pwm_out * .866;
			int pitch_out 		= g.rc_2.pwm_out / 2;

			//left front
			motor_out[CH_2]		= g.rc_3.radio_out + roll_out + pitch_out;

			//right front
			motor_out[CH_1]		= g.rc_3.radio_out - roll_out + pitch_out;

			// rear
			motor_out[CH_4] 	= g.rc_3.radio_out - g.rc_2.pwm_out;

			// this is a compensation for the angle of the yaw motor. Its linear, but should work ok.
			//motor_out[CH_4]		+= (float)(abs(g.rc_4.control_in)) * .013;

			// servo Yaw
			APM_RC.OutputCh(CH_7, g.rc_4.radio_out);


		}else if (g.frame_type == HEXAX_FRAME) {
			//Serial.println("6_FRAME");

			int roll_out 		= (float)g.rc_1.pwm_out * .866;
			int pitch_out 		= g.rc_2.pwm_out / 2;

			//left side
			motor_out[CH_2]		= g.rc_3.radio_out + g.rc_1.pwm_out;		// CCW
			motor_out[CH_3]		= g.rc_3.radio_out + roll_out + pitch_out;	// CW
			motor_out[CH_8]     = g.rc_3.radio_out + roll_out - pitch_out;	// CW

			//right side
			motor_out[CH_1]		= g.rc_3.radio_out - g.rc_1.pwm_out;		// CW
            motor_out[CH_7] 	= g.rc_3.radio_out - roll_out + pitch_out;	// CCW
			motor_out[CH_4] 	= g.rc_3.radio_out - roll_out - pitch_out;	// CCW

			motor_out[CH_2]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_7]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_4] 	+= g.rc_4.pwm_out;	// CCW

			motor_out[CH_3]		-= g.rc_4.pwm_out;	// CW
			motor_out[CH_1]		-= g.rc_4.pwm_out;	// CW
			motor_out[CH_8]		-= g.rc_4.pwm_out;  // CW

		}else if (g.frame_type == HEXAP_FRAME) {
			//Serial.println("HEXAP_FRAME");
			int roll_out 		= g.rc_1.pwm_out;
			int pitch_out 		= (float)g.rc_2.pwm_out * .5;

			//Back side
			motor_out[CH_8]		= g.rc_3.radio_out - g.rc_2.pwm_out;		// CCW
			motor_out[CH_1]		= g.rc_3.radio_out + roll_out - pitch_out;	// CW
			motor_out[CH_3]          = g.rc_3.radio_out - roll_out - pitch_out;	// CW

			//Front side
			motor_out[CH_7]		= g.rc_3.radio_out + g.rc_2.pwm_out;		// CW
                        motor_out[CH_2] 	= g.rc_3.radio_out + roll_out + pitch_out;	// CCW
			motor_out[CH_4] 	= g.rc_3.radio_out - roll_out + pitch_out;	// CCW

			motor_out[CH_8]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_2]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_4] 	+= g.rc_4.pwm_out;	// CCW

			motor_out[CH_1]		-= g.rc_4.pwm_out;	// CW
			motor_out[CH_7]		-= g.rc_4.pwm_out;	// CW
			motor_out[CH_3]		-= g.rc_4.pwm_out;      // CW

		}else if (g.frame_type == Y6_FRAME) {
			//Serial.println("Y6_FRAME");

			int roll_out 		= (float)g.rc_1.pwm_out * .866;
			int pitch_out 		=  g.rc_2.pwm_out / 2;

			//left
			motor_out[CH_2]		= ((g.rc_3.radio_out * Y6_scaling) + roll_out + pitch_out);  // CCW TOP
			motor_out[CH_3]		=  g.rc_3.radio_out + roll_out + pitch_out;			// CW

			//right
			motor_out[CH_7]		= ((g.rc_3.radio_out * Y6_scaling) - roll_out + pitch_out);	// CCW TOP
			motor_out[CH_1]		=  g.rc_3.radio_out - roll_out + pitch_out;			// CW

			//back
			motor_out[CH_8]     = ((g.rc_3.radio_out * Y6_scaling) - g.rc_2.pwm_out);	// CCW TOP
			motor_out[CH_4] 	=  g.rc_3.radio_out - g.rc_2.pwm_out;			// CW

			//yaw
			motor_out[CH_2]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_7]		+= g.rc_4.pwm_out;	// CCW
			motor_out[CH_8] 	+= g.rc_4.pwm_out;	// CCW

			motor_out[CH_3]		-= g.rc_4.pwm_out;	// CW
			motor_out[CH_1]		-= g.rc_4.pwm_out;	// CW
			motor_out[CH_4]		-= g.rc_4.pwm_out;  // CW

    	}else{

			//Serial.print("frame error");

		}


		// limit output so motors don't stop
		motor_out[CH_1]		= constrain(motor_out[CH_1], 	out_min, g.rc_3.radio_max.get());
		motor_out[CH_2]		= constrain(motor_out[CH_2], 	out_min, g.rc_3.radio_max.get());
		motor_out[CH_3]		= constrain(motor_out[CH_3], 	out_min, g.rc_3.radio_max.get());
		motor_out[CH_4] 	= constrain(motor_out[CH_4], 	out_min, g.rc_3.radio_max.get());


		if ((g.frame_type == HEXAX_FRAME) || (g.frame_type == HEXAP_FRAME) || (g.frame_type == Y6_FRAME)) {
			motor_out[CH_7]		= constrain(motor_out[CH_7], 	out_min, g.rc_3.radio_max.get());
			motor_out[CH_8]		= constrain(motor_out[CH_8], 	out_min, g.rc_3.radio_max.get());
		}

		if (num++ > 25){
			num = 0;

			//Serial.print("kP: ");
			//Serial.println(g.pid_stabilize_roll.kP(),3);
			//*/


			/*
			Serial.printf("yaw: %d, lat_e: %ld, lng_e: %ld, \tnlat: %ld, nlng: %ld,\tnrll: %ld, nptc: %ld, \tcx: %.2f, sy: %.2f, \ttber: %ld, \tnber: %ld\n",
					(int)(dcm.yaw_sensor / 100),
					lat_error,
					long_error,
					nav_lat,
					nav_lon,
					nav_roll,
					nav_pitch,
					cos_yaw_x,
					sin_yaw_y,
					target_bearing,
					nav_bearing);
			//*/

			/*

			gcs_simple.write_byte(control_mode);
			//gcs_simple.write_int(motor_out[CH_1]);
			//gcs_simple.write_int(motor_out[CH_2]);
			//gcs_simple.write_int(motor_out[CH_3]);
			//gcs_simple.write_int(motor_out[CH_4]);

			gcs_simple.write_int(g.rc_3.servo_out);

			gcs_simple.write_int((int)(dcm.yaw_sensor 	/ 100));

			gcs_simple.write_int((int)nav_lat);
			gcs_simple.write_int((int)nav_lon);
			gcs_simple.write_int((int)nav_roll);
			gcs_simple.write_int((int)nav_pitch);

			//gcs_simple.write_int((int)(cos_yaw_x * 100));
			//gcs_simple.write_int((int)(sin_yaw_y * 100));

			gcs_simple.write_long(current_loc.lat);	//28
			gcs_simple.write_long(current_loc.lng);	//32
			gcs_simple.write_int((int)current_loc.alt);	//34

			gcs_simple.write_long(next_WP.lat);
			gcs_simple.write_long(next_WP.lng);
			gcs_simple.write_int((int)next_WP.alt);		//44

			gcs_simple.write_int((int)(target_bearing 	/ 100));
			gcs_simple.write_int((int)(nav_bearing 		/ 100));
			gcs_simple.write_int((int)(nav_yaw 			/ 100));

			if(altitude_sensor == BARO){
				gcs_simple.write_int((int)g.pid_baro_throttle.get_integrator());
			}else{
				gcs_simple.write_int((int)g.pid_sonar_throttle.get_integrator());
			}

			gcs_simple.write_int(g.throttle_cruise);
			gcs_simple.write_int(g.throttle_cruise);

			//24
			gcs_simple.flush(10); // Message ID

			//*/
			//Serial.printf("\n tb  %d\n", (int)(target_bearing 	/ 100));
			//Serial.printf("\n nb  %d\n", (int)(nav_bearing 	/ 100));
			//Serial.printf("\n dcm %d\n", (int)(dcm.yaw_sensor 	/ 100));

			/*Serial.printf("a %ld, e %ld, i %d, t %d, b %4.2f\n",
					current_loc.alt,
					altitude_error,
					(int)g.pid_baro_throttle.get_integrator(),
					nav_throttle,
					angle_boost());
			*/
		}

		// Send commands to motors
		if(g.rc_3.servo_out > 0){

			APM_RC.OutputCh(CH_1, motor_out[CH_1]);
			APM_RC.OutputCh(CH_2, motor_out[CH_2]);
			APM_RC.OutputCh(CH_3, motor_out[CH_3]);
			APM_RC.OutputCh(CH_4, motor_out[CH_4]);
			// InstantPWM
			APM_RC.Force_Out0_Out1();
			APM_RC.Force_Out2_Out3();

			if ((g.frame_type == HEXAX_FRAME) || (g.frame_type == Y6_FRAME)) {
				APM_RC.OutputCh(CH_7, motor_out[CH_7]);
				APM_RC.OutputCh(CH_8, motor_out[CH_8]);
				APM_RC.Force_Out6_Out7();
			}

		}else{

			APM_RC.OutputCh(CH_1, g.rc_3.radio_min);
			APM_RC.OutputCh(CH_2, g.rc_3.radio_min);
			APM_RC.OutputCh(CH_3, g.rc_3.radio_min);
			APM_RC.OutputCh(CH_4, g.rc_3.radio_min);
			// InstantPWM
			APM_RC.Force_Out0_Out1();
			APM_RC.Force_Out2_Out3();

			if ((g.frame_type == HEXAX_FRAME) || (g.frame_type == Y6_FRAME)) {
				APM_RC.OutputCh(CH_7, g.rc_3.radio_min);
				APM_RC.OutputCh(CH_8, g.rc_3.radio_min);
				APM_RC.Force_Out6_Out7();
			}
		}

	}else{
		// our motor is unarmed, we're on the ground
		//reset_I();

		if(g.rc_3.control_in > 0){
			// we have pushed up the throttle
			// remove safety
			motor_auto_safe = true;
		}

		// fill the motor_out[] array for HIL use
		for (unsigned char i = 0; i < 8; i++) {
			motor_out[i] = g.rc_3.radio_min;
		}

		// Send commands to motors
		APM_RC.OutputCh(CH_1, motor_out[CH_1]);
		APM_RC.OutputCh(CH_2, motor_out[CH_2]);
		APM_RC.OutputCh(CH_3, motor_out[CH_3]);
		APM_RC.OutputCh(CH_4, motor_out[CH_4]);


		if ((g.frame_type == HEXAX_FRAME) || (g.frame_type == Y6_FRAME)){
			APM_RC.OutputCh(CH_7, motor_out[CH_7]);
			APM_RC.OutputCh(CH_8, motor_out[CH_8]);
		}

		// reset I terms of PID controls
		//reset_I();

		// Initialize yaw command to actual yaw when throttle is down...
		g.rc_4.control_in = ToDeg(dcm.yaw);
	}
 }

