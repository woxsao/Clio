# Use Ubuntu 20.04 as the base image
FROM osrf/ros:noetic-desktop-full

# Set up the working directory
WORKDIR /root

# Install common dependencies
RUN apt update && apt install -y \
    git \
    python3-pip \
    ros-noetic-catkin \
    curl \
    python3-vcstool \
    && rm -rf /var/lib/apt/lists/*

# Source ROS setup script
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

# Install catkin tools
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -sSL 'http://packages.ros.org/ros.key' | apt-key add - && \
    apt-get update && \
    apt-get install -y python3-catkin-tools && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

# Create a catkin workspace
RUN mkdir -p /root/catkin_ws/src && \
    cd /root/catkin_ws && \
    catkin init && \
    catkin config --extend /opt/ros/noetic && \
    catkin config -a --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DGTSAM_TANGENT_PREINTEGRATION=OFF -DGTSAM_BUILD_WITH_MARCH_NATIVE=OFF -DOPENGV_BUILD_WITH_MARCH_NATIVE=OFF

RUN rosdep update

RUN --mount=type=ssh cd /root/catkin_ws/src && \
    git clone git@github.com:woxsao/Clio.git -b feature/docker clio --recursive && \
    vcs import . < clio/install/clio.rosinstall && \
    apt-get update && \
    rosdep install --from-paths . --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/* && \
    catkin build -c -s

RUN pip install /root/catkin_ws/src/semantic_inference/semantic_inference[openset]

RUN echo "source /root/catkin_ws/devel/setup.bash" >> ~/.bashrc

WORKDIR /root/catkin_ws

# Set default command to bash
CMD ["bash"]

