if (simGetScriptExecutionCount()==0) then
    -- Make sure we have version 2.4.12 or above (the omni-wheels are not supported otherwise)
	--v=simGetIntegerParameter(sim_intparam_program_version)
	--if (v<20412) then
		--simDisplayDialog('Warning','The YouBot model is only fully supported from V-REP version 2.4.12 and above.&&nThis simulation will not run as expected!',sim_dlgstyle_ok,false,'',nil,{0.8,0,0,0,0,0})
	--end

	-- This is executed exactly once, the first time this script is executed
   --bubbleRobBase=simGetObjectAssociatedWithScript(sim_handle_self) -- this is bubbleRob's handle
    -- following is the handle of bubbleRob's associated UI (user interface):
    --ctrl=simGetUIHandle("bubbleCtrl")
    -- Set the title of the user interface: 
    --simSetUIButtonLabel(ctrl,0,simGetObjectName(bubbleRobBase).."speed") 
	bodyElements=simGetObjectHandle("Start")
	Lwheel=simGetObjectHandle("intermediate1")
	Rwheel=simGetObjectHandle("intermediate3")
    motor1=simGetObjectHandle("motor1") -- Handle of the front right motor
    motor2=simGetObjectHandle("motor2") -- Handle of the back right motor
	motor3=simGetObjectHandle("motor3") -- Handle of the front left motor
    motor4=simGetObjectHandle("motor4") -- Handle of the back left motor
	minMaxSpeed={-10*math.pi/180,8600*math.pi/180} -- Min and max speeds for each motor
    proxSens={-1,-1,-1,-1,-1,-1,-1} --Proximity sensors
	proxSens[1]=simGetObjectHandle("frontSensor") -- Handle of the proximity sensor
    proxSens[2]=simGetObjectHandle ("rightSensor") -- Proximity sensor in front inclined to right
	proxSens[3]=simGetObjectHandle ("leftSensor") -- Proximity sensor in front inclined to left
	proxSens[4]=simGetObjectHandle ("left45Sensor") -- Proximity sensor in front inclined to left
	proxSens[5]=simGetObjectHandle ("right45Sensor") -- Proximity sensor in front inclined to left
	proxSens[6]=simGetObjectHandle ("leftLateral") -- Proximity sensor in front inclined to left
	proxSens[7]=simGetObjectHandle ("rightLateral") -- Proximity sensor in front inclined to left
	speed=minMaxSpeed[2]--+(minMaxSpeed[2]-minMaxSpeed[1])--*simGetUISlider(ctrl,3)/1000 
	backUntilTime=-1
	Time=-1
	m=0
	c1=1 --Scaling factor for attractive potential
--------------------------------------------------------------------------------------------
--Initialization Follow Path	
	backwardModeUntilTime=0
	randomModeUntilTime=0
	pathCalculated=0 -- 0=not calculated, 1=beeing calculated, 2=calculated
	tempPathSearchObject=-1
	currentPosOnPath=0
	nominalVelocity=8600*math.pi/180
	leftV1=0
	leftV2=0
	rightV1=0
	rightV2=0
	path_plan_handle=simGetPathPlanningHandle("PathCollection")
	--planstate=simSearchPath(path_plan_handle, 5)
	path_handle=simGetObjectHandle("Path")
	pos_on_path=0 --position towards the path
	--dis=0 --distance from the robot to the point on the path
	--start_dummy_handle=simGetObjectHandle("Start")
	atest=-1
	targetHandle=simGetObjectHandle('Bill')
	collidableForPathPlanning=simGetObjectHandle('Collision')
	obstacles=simGetCollectionHandle('Obstacles')
	desiredTargetPos={-99,-99}
--------------------------------------------------------------------------------------------
end
-- if any child script is attached to the bubbleRob tree, this command will execute it/them:
simHandleChildScript(sim_handle_all_except_explicit)
-- If we detected something, we set the backward mode:
path_length=simGetPathLength(path_handle)
-- Retrieve the desired speed from the user interface: 
	s=simGetObjectSizeFactor(bodyElements)
	noDetectionDistance=0.37
	proxSensDist={noDetectionDistance,noDetectionDistance,noDetectionDistance,noDetectionDistance,noDetectionDistance,noDetectionDistance,noDetectionDistance}
	currentTime=simGetSimulationTime()
	--function to read the sensors
	for i=1,7,1 do
		result,dist=simReadProximitySensor(proxSens[i])
		if (result>0) and (dist<noDetectionDistance) then
			proxSensDist[i]=dist
		end
		print ("Result is:", result)
	end
	print ("backUntilTime=",backUntilTime)
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
	if (proxSensDist[1]+proxSensDist[2]+proxSensDist[3]==noDetectionDistance*3) then
		-- Nothing in front. Maybe we have an obstacle on the side, in which case we wanna keep a constant distance with it:
		
		if (proxSensDist[4]>0.25) and (proxSensDist[4]<noDetectionDistance) then
			left1=-speed/100
			left2=-speed/100
			right3=-speed/500
			right4=-speed/500
			print("Sensor left 2")
			Time=simGetSimulationTime()+1
			if (proxSensDist[6]>0.1) and (proxSensDist[6]<0.21) then
				backUntilTime=simGetSimulationTime()+1
				m=3
				proxSensDist[6]=0
				print("Sensor lateral left and left 2")
			end
		end
		if (proxSensDist[5]>0.25) and (proxSensDist[5]<noDetectionDistance) then
			left1 = -speed/500
			left2 = -speed/500
			right3 = -speed/100
			right4 = -speed/100
			print("Sensor right 2")
			Time=simGetSimulationTime()+1
			if (proxSensDist[7]>0.1) and (proxSensDist[7]<0.21) then
				backUntilTime=simGetSimulationTime()
				m=4
				proxSensDist[7]=0
				print("Sensor lateral 2 and right 2")
			end
		end
		if (proxSensDist[6]>0.1) and (proxSensDist[6]<0.21) then
			backUntilTime=simGetSimulationTime()+1
			m=3
			print("Sensor lateral left")
			Time=simGetSimulationTime()+1
			proxSensDist[6]=0
		end
		if (proxSensDist[7]>0.1) and (proxSensDist[7]<0.21) then
			backUntilTime=simGetSimulationTime()+1
			m=4
			print("Sensor lateral right")
			Time=simGetSimulationTime()+1
			proxSensDist[7]=0
		end
	else
		-- Obstacle in front.
		if (proxSensDist[3]>0.25) and (proxSensDist[3]<noDetectionDistance) then
			left1=-speed/100
			left2=-speed/100
			right3=-speed/500
			right4=-speed/500
			print("Sensor left 1")
			Time=simGetSimulationTime()+1
			if (proxSensDist[3]>proxSensDist[1]) then
				if (proxSensDist[1]>0.25) and (proxSensDist[1]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 1
					m=2
					print("Inverting Rotation sensor left 1")
					proxSensDist[1]=0
				end
			end
			if (proxSensDist[3]<proxSensDist[1]) then
				if (proxSensDist[1]>0.25) and (proxSensDist[1]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 1
					m=1
					print("Normal Rotation sensor left 1")
					proxSensDist[1]=0
				end
			end
			if (proxSensDist[1]>0.25) and (proxSensDist[1]<noDetectionDistance) then
				backUntilTime=simGetSimulationTime() + 3
				m=1
				print("Sensor front")
				proxSensDist[1]=0
			end
			if (proxSensDist[6]>0.1) and (proxSensDist[6]<0.21) then
				backUntilTime=simGetSimulationTime()+3
				m=3
				print("Sensor lateral left")
				proxSensDist[6]=0
			end
			if (proxSensDist[3]>proxSensDist[2]) then
				if (proxSensDist[2]>0.25) and (proxSensDist[2]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 5
					m=2
					print("Inverting Rotation sensor left 1")
					proxSensDist[2]=0
				end
			end
			if (proxSensDist[3]<proxSensDist[2]) then
				if (proxSensDist[2]>0.25) and (proxSensDist[2]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 3
					m=1
					print("Normal Rotation sensor left 1")
					proxSensDist[2]=0
				end
			end
						
		end
		if (proxSensDist[2]>0.25) and (proxSensDist[2]<noDetectionDistance) then
			left1 = -speed/500
			left2 = -speed/500
			right3 = -speed/100
			right4 = -speed/100
			Time=simGetSimulationTime()+1
			print("Sensor right 1")	
			if (proxSensDist[2]>proxSensDist[1]) then
				if (proxSensDist[1]>0.25) and (proxSensDist[1]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 3
					m=1
					print("Normal Rotation sensor right 1")
					proxSensDist[1]=0
				end
			end
			if (proxSensDist[2]<proxSensDist[1]) then
				if (proxSensDist[1]>0.25) and (proxSensDist[1]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 5
					m=2
					print("Inverting Rotation sensor right 1")
					proxSensDist[1]=0
				end
			end
			if (proxSensDist[7]>0.1) and (proxSensDist[7]<0.21) then
				backUntilTime=simGetSimulationTime()+1
				m=4
				print("Sensor lateral right")
				proxSensDist[7]=0
			end
			if (proxSensDist[2]>proxSensDist[3]) then
				if (proxSensDist[3]>0.25) and (proxSensDist[3]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 3
					m=1
					print("Normal Rotation sensor right 1")
					proxSensDist[2]=0
				end
			end
			if (proxSensDist[2]<proxSensDist[3]) then
				if (proxSensDist[3]>0.25) and (proxSensDist[3]<noDetectionDistance) then
					backUntilTime=simGetSimulationTime() + 5
					m=2
					print("Inverting Rotation sensor right 1")
					proxSensDist[2]=0
				end
			end
			
		end
		if (proxSensDist[2]>0.25) and (proxSensDist[2]<noDetectionDistance) and (proxSensDist[3]>0.25) and (proxSensDist[3]<noDetectionDistance) then
			backUntilTime=simGetSimulationTime() + 5
			m=1
			print("Sensor front")
			proxSensDist[1]=0
			if (proxSensDist[6]>0.1) and (proxSensDist[6]<0.21) then
				backUntilTime=simGetSimulationTime()+1
				m=3
				print("Sensor lateral left")
				proxSensDist[6]=0
			end
			if (proxSensDist[7]>0.1) and (proxSensDist[7]<0.21) then
				backUntilTime=simGetSimulationTime()+1
				m=4
				print("Sensor lateral right")
				proxSensDist[7]=0
			end
		end
		if (proxSensDist[1]>0.25) and (proxSensDist[1]<noDetectionDistance) then
				backUntilTime=simGetSimulationTime()+3
				Time=simGetSimulationTime()+1
				m=1
				print("just sensor front")
		end
	end
-------------------------------------------------------------------------------------------------------
	currentTime=simGetSimulationTime()
	if (result>0) then
		backwardModeUntilTime=currentTime+3 -- 3 seconds backwards
	end
------------------------------------------------------------------------------------------------
print("Time is:",Time)
print("Current time is",currentTime)
print("backwardModeUntilTime is:",backwardModeUntilTime)
-- When in backward mode, we simply backup in a curve at reduced speed
if (Time<simGetSimulationTime()) then
	--targetP=simGetObjectPosition(targetHandle,-1)
	--vv={targetP[1]-desiredTargetPos[1],targetP[2]-desiredTargetPos[2]}
	--if (math.sqrt(vv[1]*vv[1]+vv[2]*vv[2])>0.01) then
		--pathCalculated=0 -- We have to recompute the path since the target position has moved
		--desiredTargetPos[1]=targetP[1]
		--desiredTargetPos[2]=targetP[2]
	--end


	if (currentTime<backwardModeUntilTime) then
		-- Sensors detected something. We are too close to continue using a precalculated path, we navigate blindly a little bit back
		pathCalculated=0
	else
		rightV1=0
		rightV2=0
		leftV1=0
		leftV2=0
		if (pathCalculated==0) then
			if (simCheckCollision(obstacles,collidableForPathPlanning)~=1) then -- Make sure we are not colliding when starting to compute the path!
				if (tempPathSearchObject~=-1) then 	
					simPerformPathSearchStep(tempPathSearchObject,true) -- delete any previous temporary path search object
				end
				orientation=simGetObjectOrientation(bodyElements,-1)
				simSetObjectOrientation(bodyElements,-1,{0,0,orientation[3]}) -- Temporarily set the robot's orientation to be in the plane (the robot can slightly tilt back and forth)
				tempPathSearchObject=simInitializePathSearch(path_plan_handle,10,0.03) -- search for a maximum of 10 seconds
				simSetObjectOrientation(bodyElements,-1,orientation) -- Set the previous robot's orientation
				if (tempPathSearchObject~=-1) then
					pathCalculated=1
				end
			else
				if (currentTime>randomModeUntilTime) then
					randomModeUntilTime=currentTime+2 -- 2 seconds in random direction
					randomVLeft=(-1+math.random()*2)*nominalVelocity
					randomVRight=(-1+math.random()*2)*nominalVelocity
				end
			end
		else
			if (pathCalculated==1) then
				r=simPerformPathSearchStep(tempPathSearchObject,false)
				if (r<1) then
					if (r~=-2) then
						pathCalculated=0 -- path search failed, try again from the beginning
						tempPathSearchObject=-1
					end
				else
					pathCalculated=2 -- we found a path
					currentPosOnPath=0
					tempPathSearchObject=-1
				end
			else
				l=simGetPathLength(path_handle)
				r=simGetObjectPosition(bodyElements,-1)
				l_wheel=simGetObjectPosition(Lwheel,-1)
				r_wheel=simGetObjectPosition(Rwheel,-1)
				end_position=simGetObjectPosition(targetHandle,-1)
				--while true do
					--p=simGetPositionOnPath(path_handle,currentPosOnPath/l)
					--p=simGetObjectPosition(targetHandle,-1)
					--d=math.sqrt((p[1]-r[1])*(p[1]-r[1])+(p[2]-r[2])*(p[2]-r[2]))
					--dleft=math.sqrt((p[1]-l_wheel[1])*(p[1]-l_wheel[1])+(p[2]-l_wheel[2])*(p[2]-l_wheel[2]))
					--dright=math.sqrt((p[1]-r_wheel[1])*(p[1]-r_wheel[1])+(p[2]-r_wheel[2])*(p[2]-r_wheel[2]))
					--dwheel=math.sqrt((end_position[1]-r[1])*(end_position[1]-r[1])+(end_position[2]-r[2])*(end_position[2]-r[2]))
					--if (d>0.10)or(currentPosOnPath>=l) then
					--	break
					--end
					--currentPosOnPath=currentPosOnPath+0.01
				--end
				p=simGetObjectPosition(targetHandle,-1)
				d=math.sqrt((p[1]-r[1])*(p[1]-r[1])+(p[2]-r[2])*(p[2]-r[2]))
				s=simGetObjectMatrix(bodyElements,-1)
				s=simGetInvertedMatrix(s)
				p=simMultiplyVector(s,p)
				targetOrientation=simGetObjectOrientation(targetHandle,-1)
				robotOrientation=simGetObjectOrientation(bodyElements,-1)
				robotOrientation=robotOrientation[3]
				if (robotOrientation>=0) then
					robotOrientation=robotOrientation-math.pi/2
				else
					robotOrientation=robotOrientation+3*math.pi/2
				end
				Vtarget_table=simGetObjectVelocity(targetHandle)
				Vtarget=math.sqrt((Vtarget_table[1]*Vtarget_table[1])+(Vtarget_table[2]*Vtarget_table[2]))
				angleTarget=math.pi+targetOrientation[3] --Orientation of the target related to x axis
				-- Now p is relative to the robot
				a=math.atan2(p[2],p[1])
				--Use Potential Field equations
				Vrobot=math.sqrt((Vtarget*Vtarget)+(2*c1*d*math.cos(angleTarget-a))+((c1*c1)*(d*d)))
				angleRobot=a+math.asin((Vtarget*math.sin(angleTarget-a))/Vrobot)
				if (Vtarget==0) then
					angleRobot=robotOrientation
				end
				diff=angleRobot-robotOrientation
				conv_diff=diff*180/math.pi
				aTarget_degree=angleTarget*180/math.pi
				aRobot_degree=angleRobot*180/math.pi
				aRobot_orientation=robotOrientation*180/math.pi
				adegree=a*180/math.pi
				print("The target angle is:",angleTarget*180/math.pi)
				print("The velocity of target is:", Vtarget)
				print("The velocity of the robot is:",Vrobot)
				print("The angle related to the vector distance is:",a*180/math.pi)
				print("THE DIFFERENCE IS:",diff*180/math.pi)
				print("THE ANGULAR DIFFERENCE BETWEEN ROBOT AND TARGET IS:",aTarget_degree-aRobot_degree)
				print("THE ROBOT ORIENTATION IS:",robotOrientation*180/math.pi)
				if (d<=0.60) then
					Vn=Vrobot*0.5
				else
					Vn=Vrobot
				end
				if (conv_diff<0) and (conv_diff>=-2) then
					if (Vtarget==0) and (d<=0.8) then
						leftV1=0
						leftV2=0
						rightV1=0
						rightV2=0
					else
						if (aTarget_degree-aRobot_degree<-2) and (d>0.6) and (d<=1.2) then
							rightV1=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
							rightV2=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
							leftV1=-Vn*2
							leftV2=-Vn*2
							print ("ANGULAR DIFFERENCE")
						else
							if (d>1.2) and (aTarget_degree-aRobot_degree<-10) then
								rightV1=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
								rightV2=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
								leftV1=-Vn*2
								leftV2=-Vn*2
							else
								if (d>1.2) and (aTarget_degree-aRobot_degree>10) then
									leftV1=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
									leftV2=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
									rightV1=-Vn*2
									rightV2=-Vn*2
									print("Turning left")
								else
									rightV1=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
									rightV2=-Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
									leftV1=-Vn*0.25
									leftV2=-Vn*0.25
								end
							end
						end
					end
				else
					if (conv_diff<-5) and (d>0.6) and (d<=1.2) then
						rightV1=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
						rightV2=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
						leftV1=-Vn*2
						leftV2=-Vn*2
						print("difference is lower than -10")
					end
					if (conv_diff<-5) and (d>1.2) then
						if (aTarget_degree-aRobot_orientation>20) then
							leftV1=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
							leftV2=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
							rightV1=-Vn*2
							rightV2=-Vn*2
							print("turning left, orientation")
						else
							if (Vn>6.5) then
								Vn=6.5
							else
								Vn=Vn
							end
							rightV1=-Vn
							rightV2=-Vn
							leftV1=-Vn
							leftV2=-Vn
							print("going forward, orientation")
						end
					end
				end
				if (conv_diff>0) and (conv_diff<=2) then
					if (Vtarget==0) and (d<=0.8) then
						leftV1=0
						leftV2=0
						rightV1=0
						rightV2=0
					else
						if (aTarget_degree-aRobot_degree>5) and (d>0.6) and (d<1) then
							rightV1=-Vn
							rightV2=-Vn
							leftV1=Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
							leftV2=Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
							print ("ANGULAR DIFFERENCE")
						else
							if (d>1) and (aTarget_degree-aRobot_orientation>15) then
								rightV1=-Vn*2
								rightV2=-Vn*2
								leftV1=-Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
								leftV2=-Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
								print("Trying to find target")
							else
								if (Vn>6.5) then
									Vn=6.5
								else
									Vn=Vn
								end
								leftV1=-Vn
								leftV2=-Vn
								rightV1=-Vn
								rightV2=-Vn
								print("going forward")
							end
						end
					end
				else
					if (conv_diff>5) then
						if (conv_diff>2) and (d>0.6) and (d<=1) then
							leftV1=Vn
							leftV2=Vn
							rightV1=Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
							rightV2=Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
							print("difference is bigger than 10, small distance")
						end
						if (conv_diff>5) and (d>1) and (d<=1.2)then
							leftV1=Vn
							leftV2=Vn
							rightV1=Vn*(1-2*angleRobot/(math.pi*0.5))
							rightV2=Vn*(1-2*angleRobot/(math.pi*0.5))
							print("difference is bigger than 10, big distance")
						end
						if (d>1.2) and (d<=1.6) and (aTarget_degree-aRobot_orientation>20) then
							leftV1=Vn
							leftV2=Vn
							rightV1=Vn*(1-2*angleRobot/(math.pi*0.5))
							rightV2=Vn*(1-2*angleRobot/(math.pi*0.5))
							print("difference is bigger than 10, turning")
						end
						if (d>1.6) and (aTarget_degree-aRobot_orientation>20) and (aTarget_degree-aRobot_orientation<=30) then
							if (Vn>6.5) then
								Vn=6.5
							else
								Vn=Vn
							end
							leftV1=-Vn
							leftV2=-Vn
							rightV1=-Vn
							rightV2=-Vn
							print("going forward, very far")
						end
						if (d>1.6) and (aTarget_degree-aRobot_orientation>30) then
							leftV1=Vn*0.5
							leftV2=Vn*0.5
							rightV1=Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
							rightV2=Vn*0.5*(1-2*angleRobot/(math.pi*0.5))
						end
					end
				end
				if (conv_diff==0) then
					if (Vtarget==0) and (d<=0.8) then
						leftV1=0
						leftV2=0
						rightV1=0
						rightV2=0
						print("Stop")
					else
						if (aTarget_degree-aRobot_degree<-10) and (d>0.8) and (d<2) then
							rightV1=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
							rightV2=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
							leftV1=-Vn
							leftV2=-Vn
							print ("ANGULAR DIFFERENCE turning left")
						else
							if (aTarget_degree-aRobot_degree>10) and (d>0.8) and (d<2) then
								leftV1=Vn
								leftV2=Vn
								rightV1=Vn*(1-2*angleRobot/(math.pi*0.5))
								rightV2=Vn*(1-2*angleRobot/(math.pi*0.5))
								print ("ANGULAR DIFFERENCE turning right")
							else
								if (aTarget_degree-aRobot_degree<-5) and (d>2) then
									rightV1=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
									rightV2=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
									leftV1=-Vn
									leftV2=-Vn
								else
									if ((aTarget_degree-aRobot_degree>5) and (aTarget_degree-aRobot_degree<=20) or (aTarget_degree-aRobot_degree>35)) and (d>2) then
										leftV1=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
										leftV2=Vn*(1-2*(angleRobot-math.pi*0.5)/(math.pi*0.5))
										rightV1=-Vn
										rightV2=-Vn
									end
									if (aTarget_degree-aRobot_degree>20) and (aTarget_degree-aRobot_degree<=35) and (d>2) then
										if (Vn>6.5) then
											Vn=6.5
										else
											Vn=Vn
										end
										rightV1=-Vn
										rightV2=-Vn
										leftV1=-Vn
										leftV2=-Vn
										print("Difference equal zero. go forward")
									end
									if (aTarget_degree-aRobot_degree>=5) and (aTarget_degree-aRobot_degree<10) and (d>0.8) and (d<2) then
										if (adegree>=0) and (adegree<75) and (aRobot_degree>=0) and (aRobot_degree<90) then
											leftV1=-Vn
											leftV2=Vn
											rightV1=Vn
											rightV2=-Vn
											print("0 to 75")
										end
										if (adegree>=75) and (adegree<105) and (aRobot_degree>=0) and (aRobot_degree<90) then
											leftV1=-Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=-Vn
											print("75 to 105")
										end
										if (adegree>=105) and (adegree<180) and (aRobot_degree>=0) and (aRobot_degree<90) then
											leftV1=Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=Vn
											print("105 to 180")
										end
										if (adegree>=0) and (adegree<75) and (aRobot_degree>=90) and (aRobot_degree<180) then
											leftV1=Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=Vn
											print ("90 to 180")
										end
										if (adegree>=75) and (adegree<105) and (aRobot_degree>=90) and (aRobot_degree<180) then
											leftV1=-Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=-Vn
											print("75 to 105")
										end
										if (adegree>=105) and (adegree<180) and (aRobot_degree>=90) and (aRobot_degree<180) then
											leftV1=-Vn
											leftV2=Vn
											rightV1=Vn
											rightV2=-Vn
											print("105 to 180")
										end
									end
									if (aTarget_degree-aRobot_degree>=-10) and (aTarget_degree-aRobot_degree<-2) and (d>0.8) and (d<2) then
										if (adegree>=0) and (adegree<75) and (aRobot_degree>=0) and (aRobot_degree<90) then
											leftV1=Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=Vn
											print("0 to 75")
										end
										if (adegree>=75) and (adegree<105) and (aRobot_degree>=0) and (aRobot_degree<90) then
											leftV1=-Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=-Vn
											print("75 to 105")
										end
										if (adegree>=105) and (adegree<180) and (aRobot_degree>=0) and (aRobot_degree<90) then
											leftV1=-Vn
											leftV2=Vn
											rightV1=Vn
											rightV2=-Vn
											print ("105 to 180")
										end
										if (adegree>=0) and (adegree<75) and (aRobot_degree>=90) and (aRobot_degree<180) then
											leftV1=Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=Vn
											print("0 to 75")
										end
										if (adegree>=75) and (adegree<105) and (aRobot_degree>=90) and (aRobot_degree<180) then
											leftV1=-Vn
											leftV2=-Vn
											rightV1=-Vn
											rightV2=-Vn
											print("75 to 105")
										end
										if (adegree>=105) and (adegree<180) and (aRobot_degree>=90) and (aRobot_degree<180) then
											leftV1=-Vn
											leftV2=Vn
											rightV1=Vn
											rightV2=-Vn
											print("105 to 180")
										end
									end
									if (aTarget_degree-aRobot_degree>-5) and (aTarget_degree-aRobot_degree<5) and (d>0.8) and (d<2) then
										if (Vn>6.5) then
											Vn=6.5
										else
											Vn=Vn
										end
										leftV1=-Vn
										leftV2=-Vn
										rightV1=-Vn
										rightV2=-Vn
										print("lower than 2")
									end
									if (aTarget_degree-aRobot_degree>-15) and (aTarget_degree-aRobot_degree<15) and (d>2) then
										if (Vn>6.5) then
											Vn=6.5
										else
											Vn=Vn
										end
										leftV1=-Vn
										leftV2=-Vn
										rightV1=-Vn
										rightV2=-Vn
										print("bigger than 2")
									end
								end
							end
						end
					end	
				end
				print ("The speed at left is:",leftV1)
				print ("The speed at right is:",rightV1)
				print ("the distance between robot and target is:",d)
				print ("the Robot angle is:",angleRobot*180/math.pi)
				print ("the end position is:", end_position[1])
				print ("-------------------------")
			end
		end
		
	end

	if (currentTime<backwardModeUntilTime) then
		simSetJointTargetVelocity(motor1,-100*math.pi/180)
		simSetJointTargetVelocity(motor2,-100*math.pi/180)
		simSetJointTargetVelocity(motor3,-50*math.pi/180)
		simSetJointTargetVelocity(motor4,-50*math.pi/180)
		backwardModeUntilTime=0
	else
		if (currentTime<randomModeUntilTime) then
			simSetJointTargetVelocity(motor1,randomVLeft)
			simSetJointTargetVelocity(motor2,randomVLeft)
			simSetJointTargetVelocity(motor3,randomVRight)
			simSetJointTargetVelocity(motor4,randomVRight)
		else
			if atest<simGetSimulationTime() then
				simSetJointTargetVelocity(motor1,leftV1)
				simSetJointTargetVelocity(motor2,leftV2)
				simSetJointTargetVelocity(motor3,rightV1)
				simSetJointTargetVelocity(motor4,rightV2)
				print("searching path")
				print("the speed of motor 1:",leftV1)
				print("the speed of motor 2:",leftV2)
				print("the speed of motor 3:",rightV1)
				print("the speed of motor 4:",rightV2)
				print("The path length is:",path_length)
				print ("-----------atest----------")
			else
				simSetJointTargetVelocity(motor1,leftChange)
				simSetJointTargetVelocity(motor2,leftChange)
				simSetJointTargetVelocity(motor3,rightChange)
				simSetJointTargetVelocity(motor4,rightChange)
				print("the speed of motor 1:",leftChange)
				print("the speed of motor 2:",leftChange)
				print("the speed of motor 3:",rightChange)
				print("the speed of motor 4:",rightChange)
				print("The path length is:",path_length)
				print ("----------no_atest-------------")
			end
		end
	end
	
else
		print ("m=",m)
		print ("backUntilTime=",backUntilTime)
		if (backUntilTime<simGetSimulationTime()) then
			simSetJointTargetVelocity(motor1,left1)
			simSetJointTargetVelocity(motor2,left2)
			simSetJointTargetVelocity(motor3,right3)
			simSetJointTargetVelocity(motor4,right4)
			print("getting Sensors")
			print("Left is=",left1)
			print("Right is=",right3)
		else
			if (m==1) then
				simSetJointTargetVelocity(motor1,speed/1000)
				simSetJointTargetVelocity(motor2,speed/1000)
				simSetJointTargetVelocity(motor3,speed/100)
				simSetJointTargetVelocity(motor4,speed/100)
				print("I am here, higher, rotation")
				print("Left is=",speed/2000)
				print("Right is=",speed/100)
			end
			if (m==2) then
				simSetJointTargetVelocity(motor1,speed/100)
				simSetJointTargetVelocity(motor2,speed/100)
				simSetJointTargetVelocity(motor3,speed/1000)
				simSetJointTargetVelocity(motor4,speed/1000)
				print("I am here, Inverse")
				print("Left is=",speed/100)
				print("Right is=",speed/2000)
			end
			if (m==3) then
				simSetJointTargetVelocity(motor1,speed/200)
				simSetJointTargetVelocity(motor2,-speed/200)
				simSetJointTargetVelocity(motor3,-speed/200)
				simSetJointTargetVelocity(motor4,speed/200)
				print("I am here, lateral left")
				print("Left is=",speed/200)
				print("Right is=",speed/200)
			end
			if (m==4) then
				simSetJointTargetVelocity(motor1,-speed/200)
				simSetJointTargetVelocity(motor2,speed/200)
				simSetJointTargetVelocity(motor3,speed/200)
				simSetJointTargetVelocity(motor4,-speed/200)
				print("I am here, lateral right")
				print("Left is=",speed/200)
				print("Right is=",speed/200)
			end
		print("constant TIME is:",Time) --Distance from the robot to the path
		--print(phi,":Angle Robot") --Angle of the robot towards the path
		end
end

----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
