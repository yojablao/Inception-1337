Docker CLI ==> (DOCKER COMMAND LINE INTERFACE)

UNION FILE SYSTEM (the underlying filesysteme behind all the container and image layers)

union mount is a type of filesystem that can creat an illusion of merging content of several directories("CALLED BRANCHES OR LAYERS") into one without modifying its original (example like /home directories from NFS SERVER "computer that share files and directories over a network, allowing other computers to acsses themas if they were local" )

union file systeme is a concept with many implemetation :
	 
-KEY FEAUTURES AND MECHANICS:
		LAYERED APPROCH:
---- union filesystems stack directories on top of each other in a specific order of priority . ehen a file accessed , the filesystem looks for it in the top layer first, then the next, and so on , intil it finds the file.

		COPY-ON-WRITE(CoW):
---- often lower layers are set to read-only , and the top layer is writable. when the user tries to modify a file that exist in a read-only lower layer, the union filesystem automatically creat a copy of that file in the in  the writable layer top layer, and the changes are applied to the copy . the original file remaind untouched.

		WHITEOUTS:
---- to handle file deletion, a special "whiteout" file is created in the writable layer. This file effectivly hides the corresponding file in the lower layer from the merged view , it appear as if it has been deleted, without actually modifying the read-only branch.

UNION FILESYSTEM has multiple types here is breakdown of the popular implementation:
---- UnionFS => The original one its no longer actively developed(last coommit 2014)

---- aufs (Another Union FileSystem) => RE-implementaion of UnionFS with many new feauturres.was the default docker driver on older Debian/Ubuntu . REJECTED FOR MAINLINE LINUX KERNEL (replaced by OverlayFS in modeern Linux distrbution and docker).

---- OverlayFS ==> the modern standart for the LINUX KERNEL . included since Kernel V 3.18 (this is the default storage driver  for modern docker instalation (OVERLAY2).it is the recomanded choice.

ZFS(Zettabyte File System) - Btrfs (B-Tree File System) ...

THIS IS WHY UNION FILESYSTEM ------>> Union Filesystems are ideal for Docker because they save space and speed up container startup. Instead of copying large images for each container, containers share the read-only image layers. Each container only adds a thin, writable layer on top. This provides isolation using a "copy-on-write" (CoW) strategy: if a container needs to modify a shared file, it copies that file to its own writable layer first.


	BUILDING THE DOCKER IMAGE:
1--INSTRICTION EXECUTION : each instriction in the docker file (FROM, RUN, COPY...) is executed sequentially

2--LAYER CREATION : for every executable the docke deamon creat a new "READ-ONLY IMAGE LAYER", this layer essentialy is a snapshot of the filesystem changes resulting fron that instruction.

 
3--LAYER STACKING  : these layers  are stacked one on the top of the other , formung the complete final DOCKER IMAGE . each layer is immutable and shares the UNION FILE SYSTEM principle, where the higher layers take precedence over lower layers.

4--IMAGE STORAGE : the final image (the collection of read-only layers ) is stored in the local docker image cache and can be pushed to a regestry like docker hub.

KEY POINT :
	IF YOU BUILD TWO IMAGES USING THE SAME BASE LAYER (FROM UBUNTU) , THAT COMMON BASE LAYER IS STORED ONCE ON YOUR HOST SYSTEM AND IS SHARED BETWEEN THE TWO IMAGES .


	RUNNING A CONTAINER 
when you execute docker run <image-name> the Docker deamon perform the following:

1--LOWER DIRECTORIES(lowerdir) : it take all the read-only image layers from the specified Docker image and designates them as the lower directories in the Union mount. these are the foundation of the container's filesystem.

2--UPPER DIRECTORY(upperdir) : it creats a brand new empty , read-write layer, which is called the container layer, this layer is designated as the upper directory.

4--MERGED VIEW (/mnt/merged) : it uses the host kernel's ovverlayFS/AUFS capability instantly combine(union mount) the stack of read-only image layers (lowerdir) and the single , empty read-write container layer (upperdir) into a MERGED VIEW.

5--PROCESS START  :  the container process is started with its isolated Namespaces and cgroup, with this Merged view serving as its root filesysteme (/).

Result: The container's filesystem appears as a complete, single structure, even though it's logically composed of many stacked layers. The container is running with its own isolated view of the world.



				HOW THE HTTPS WORKS ? 
THE CLIENT >>>>>>      <<CERTIFICATE AUTHORITY>>   

