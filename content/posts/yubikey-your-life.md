---
title: Yubikeying your digital life
subtitle: A comprehensive guide on how to setup your Yubikey for most of the things you can do with it in 2020
tags: 
    - yubikey
    - security
draft: true
date: 2020-10-15T01:00:00+01:00
---

Is almost the end of 2020 and for a few years already I've been wanting to get my hands on a pair of Yubikeys to add an extra layer of security to my Laptop and important accounts. This finally happened a few weeks ago, when I recieved my two Yubikey 5 NFC. 

I did a lot of research on how to set them up properly and discovered in the process that there is a lot of information to distil and collate. For example, I was not quite into GnuPG really, and I learned quite a lot by setting up my key.

Since I went through all the hassle of configuring my own Yubikey, chasing information in different sources and making some sense of it, I had the idea that would be better if I documented the whole process. In some of the guides out there, there is not a lot about the *why* of things -- most of them are the "copy and paste this command" kind of guide. So in this guide my goal is to provide some context and let you make the choices and understand what's going on. 

So, this is my humble attempt of a comprehensive guide of most of the things that are possible with your Yubikey as of 2020. I plan to update and grow it overtime, as I learn new things.

A the moment, this guide covers:

- Making your Linux machine recognize your Yubikey with `udev` (October 2020)
- Using your Yubikey to secure your Linux machine via PAM (October 2020)
- Using your Yubikey with GnuPG (October 2020)
- Using your Yubikey with SSH (October 2020)
- Using your Yubikey to secure your accounts with WebAuthn compatible websites (October 2020)
- Using your Yubikey to unlock a LUKS Encrypted Partition (Coming soon)

> DISCLAIMER: My Yubikeys are the 5 NFC USB type. Some of the steps here may not work for your Yubikey. Feel free to comment if some steps are not applicable to your own Yubikey and I'll gladly update the guide. 

> SUPPORT: This guide is intended for Debian/Ubuntu and derivatives users with their latest versions as of 2020. Some dependencies or package names may vary in other distros. It is not my goal to compile a list of differences between distributions.

## A Word of Warning

I urge you not to follow this guide if you don't have at least two Yubikeys. This is paramount. If you lose or damage one, and you don't have a backup, that's pretty much you locking yourself out of anything you have secured with your key. So be warned!

## Making your Linux machine recognize your Yubikey with `udev`

### What `udev` does

`udev` is the Linux kernel device event system. Is basically a daemon that is constantly listening for anything that happens device related in your system. So when you plug a mouse in, or a USB stick, or event a monitor, `udev` knows about it, and you can do pretty cool things by reacting to those events using **udev rules**. If you want to read more about it, [here's this for you][udev]!

`udev` can recognize basic devices like mouses, disks and monitors without a hassle, but it might not know how to recognize a Yubikey. So the purpose of this part is teaching `udev` how to recognize that our Yubikey has been connected. 

### Adding U2F support to `udev`

It's very likely that your `udev` setup knows already how to handle your Yubikey, but we need to make sure. For this we need to check if you have the `libu2f-udev` library installed. [U2F is the standard][u2f] that the Yubikey 5 NFC USB uses for Second Factor Authentication.

You can check that the library is indeed installed with: 

```bash
dpkg -s libu2f-udev
```

There is a bunch of output here, but the line you are looking for looks like this:

```txt
Status: install ok installed
```

If `libu2f-udev` is installed, then you should see that. If not, install it with the command:

```bash
sudo apt install libu2f-udev
```

### Making sure you have the rules

`udev` works with rules, and you need to import specific U2F rules to `udev` to make your Yubikey work. This is very easy to do. Just run this command that fetches the rules from a raw file in Github and saves them into `/etc/udev/rules.d/70-u2f.rules` where the rest of the other `udev` rules in your system live. We need `sudo` because files stored under `/etc` are **root** owned.

```bash
sudo wget -O /etc/udev/rules.d/70-u2f.rules https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules
```

After you are done with this, you should reboot your system so `udev` can load the new rules on startup.

## Using your Yubikey to secure your Linux machine via PAM

### What is PAM?

PAM stands for Pluggable Authentication Modules and is a feature of the Linux Kernel that allows to extend authentication functionality by means of loading plugins and editing some configuration files. There is an excellent [overview of PAM here][pam].

The possibilities of PAM are almost infinite. You could write a PAM module that authenticates you if it recognizes your face in the camera, for example.

> PS: Don't do that. [Someone actually wrote it already][facial-pam] and really, facial recognition it's a terrible auth factor.

### Installing the U2F PAM 

So, as you might have guessed, there is a PAM for U2F capable devices like the Yubikey 5. It's almost certain that you don't have it installed, so let's do that:

```bash
sudo apt install libpam-u2f
```

This module provides you with an utility called `pamu2fcfg` that you can use to generate a config line from a U2F device that can be used in a PAM auth file. This config line is just your Yubikey public id in a format that PAM can understand.

Let's test the output first. Plug your Yubikey and type the following command. When your Yubikey flashes, gently tap the metal bit.

```bash
 pamu2fcfg
```

You should see some text in the screen that starts with your username and sort of looks like an ssh public key. That means it works, so we can run this command again but this time store the output in a file.

```bash
pamu2fcfg > ~/u2f_keys
```

Remove your primary Yubikey and insert the other one. This time we will run the same command but appending to the file we just created.

```bash
pamu2fcfg -n >> ~/u2f_keys
```

Repeat this last step for every extra Yubikey you plan to use.

> NOTE: Is really important that you run the above commands as non-root, because the key is associated with the user currently running the utility.

### Securing the file

We need to secure the file we just created, as it contains important information that should be readable only by the root user.

So, move the file to the `/etc/` directory, change the owner to root and let root be the only one capable to read it and modify it.

```bash
sudo mv ~/u2f_keys /etc/u2f_keys && sudo chown root:root /etc/u2f_keys && sudo chmod 660 /etc/u2f_keys
```

### Testing PAM Auth with `sudo`

The PAM module manages many authentication contexts. You can specify different authentication rules for when you run `sudo` commands, or when you login via a display manager like `light-dm` (desktop login), or when you login via a TTY. You could require password for `sudo`, but not for `light-dm` for example. It's totally up to you.

These rules are defined in files located under `/etc/pam.d/`. We are going to modify the `sudo` rule just for testing purposes, making the Yubikey required when we use commands with `sudo`.

> NOTE: You need to perform these steps with the utmost care, as there is a small risk of locking yourself out of your system, so read carefully.

We first need to open the pam file that contains the `sudo` config:

```bash
sudo nano /etc/pam.d/sudo
```

Then, right under the line that says `@include common-auth` you must paste the following:

```txt
auth required pam_u2f.so authfile=/etc/u2f_keys cue
```

The `auth` part tells PAM that this is an authentication rule. Then the next part tells it that it is required. Then, we specify the library that needs to be dynamically loaded for this authentication module (which is `pam_u2f.so`). Then, we specify an `authfile` that contains the keys allowed to authenticate with this scheme. And finally, we add the `cue` option, that will display a prompt telling you to touch your key when its time. That last bit is completely optional.

**Save the file but do not close it**, as if something goes wrong you are still executing `nano` as root and therefore can revert changes. Then open a new tab in the terminal and execute `sudo echo test`. You should be prompted to enter your password. Once you have done that, then the "Please touch the device" message should appear, and you should tap your Yubikey. If the command worked then congratulations: now your `sudo` commands require your Yubikey as a second factor to be executed.

### Considerations on `sudo` with UF2

Some people prefer to have U2F protection when executing `sudo` commands. I think this is a very good idea for software developers in general in spite of the hassle that sometimes comes with it. Sometimes, when working with multiple open source libraries, [you could stumble upon certain ones trying to execute malicious commands in your machine][oss-malware]. Even if an attacker can take a hold of your system password by using a keylogger or reading an `env` var, they would need your Yubikey to perform any `sudo` action. 

If this is a risk that does not concern you, then you can go ahead and remove the rule we just created from the `/etc/pam.d/sudo` file.

### Adding the Yubikey to Desktop Login and TTY Login

Something that might be more important to you is to make sure that no one can access to your Desktop Session or a TTY without your Yubikey, so we are going to do just that.

First we will go with TTY. Open the following file:

```bash
sudo nano /etc/pam.d/login
``` 

Search for the line that contains `@include common-auth` and paste in the line below it the rule you just created in the `/etc/pam.d/sudo` file. That's you done with the TTY setup. Save and close the file.

Now, depending of your operating system you might have a specific greeter. The greeter is the window for typing your username and password after the graphics service (X11 or Wayland) has been booted but before your desktop is loaded. The most recent versions of Ubuntu ship with a greeter called `gdm` but some derivatives of it like Elementary OS use `lightdm`. We need to hook into the auth process of the greeter using PAM.

For `lightdm` the file to edit is `/etc/pam.d/lightdm`. For `gdm` is `/etc/pam.d/gdm`. Edit the file with `nano` and repeat same procedure: look for the `@include common-auth` line and add the rule we created directly below it. After you are done save and close.

Then, when you restart your machine, after you enter your password to log in you should be prompted to tap your Yubikey. Testing the TTY setup is simple too. In most systems you can open a TTY pressing `alt` + `ctrl` + one of the F keys (F1 to F12). This might freeze your system for some ten seconds.

When you press you should be able to see a screen to input your username and log in to the system. That should also ask you for your Yubikey after your password has been typed correctly.

To come back to your desktop session, you need to press `alt` + `ctrl` again + the F key where your session is running. This varies from distro to distro. In Ubuntu is usually `F2`. I've seen that Elementary OS is `F7`. Sometimes is just trial and error. Otherwise, you can always `reboot` from the TTY if for some reason you are unable to come back to your desktop.

This pretty much covers the basic things you can do with your Yubikey to secure your Linux machine using PAM.

## Using your Yubikey with GnuPG

### GPG

GPG stands for Gnu Privacy Guard, which is an implementation of the OpenPGP message format defined in [RFC 4880](https://tools.ietf.org/html/rfc4880). Basically, it's a way of doing public-key (asymmetric) cryptography.

GPG has widespread use in the Linux community, and it is used with a multitude of purposes. Package repositories sign files and sha-sums with their keys to ensure that nobody tampers with the package contents. Wistleblowers send encrypted messages using their keys via email to their trusted contacts. Sysadmins authenticate with consoles in remote machines using their keys, and can grant access to others by signing sub keys. Ddevelopers sign code contributions to prevent malicious impersonation.

In GPG, everything starts with a **master key**. This is the most important file of your keyring, and it is meant to be shared with no one. This is the ultimate proof of your identity online, and I suggest you take care of your private key with the utmost care. Mine is stored in a USB in safe location, absolutely offline. And even if you take a hold of it, you'll need the passphrase to do anything with it.

How do you use the master key then if is not in your computer? Well, this is where the concept of subkeys comes into play. The idea behind GPG, is that you have a set of subkeys specially crafted for encrypting, signing and authenticating. All these keys are derived from the master, but are different. The cool thing is that all of them, inlcuding your master one, share the same public part. This means that any subkey derived from your master can be validated against the same public key.

Traditionally, GPG keys are stored in your computer. But Yubikeys are so amazing that they allow you to store three keys inside them and proctect them with a PIN. So if you need to encrypt or sign something, or authenticate against a remote machine, you need your Yubikey plugged in order to be allowed to use the keys inside it.

Pretty nifty, huh?

#### Creating a Master Key

So, we are going to setup your YubiKeys to do just that. If you are new to GPG, you probably don't have a master key yet. Hereby we will create your most important key.

But first, make sure we have gpg with:

```bash
sudo apt install -y gnupg2 gnupg-agent
```


Then, we create your master key:

```bash
gpg --gen-key
```

Then, you should see an output asking you for the type of key. Select option 4 (RSA Sign only).

Then, you'll be asked for the keysize. 4096 is the most secure option so go with it.

> NOTICE: Some old Yubikeys do not support 4096 bits of size for their keys. Check before. If you have a v4 or a v5 NFC like me, you'll be fine.

Lastly, you will be asked if you want to set up an expiration date. Expiring a master key does not have a lot of sense, so select 0 for make the key valid forever. Confirm that it does not expire and move on.


You'll be asked to add an identity to your key. You can write your name, a comment and an email. Mine is "Matias Navarro-Carter (Personal) <mnavarrocarter@gmail.com>".

Then, after running some entropy generation your brand new master key will be created and ultimately trusted in your system. Congrats!

#### Importing a Master Key (Optional)

If you already have a master key and you want to import it, you should do:

```bash
gpg --import /path/to/your/pem/formatted/master/key
```

> NOTE: You will be asked to write your passphrase if your key is encrypted.

### Adding more Identities

If you have more than one email (for example, a work email or an email from your open source organization) you might want to add those to your key, as it will be useful for things like commit signing and stuff.

Grab your key id with:

```bash
gpg --list-keys
```

And then run:

```bash
gpg --edit-key <your-key-id>
```

This will start the `gpg>` prompt. Now you can run the command to add an identity.

```bash
gpg> adduid
```

Follow the intructions to add your name, comment and email. Once you have confirmed, you can save your changes to your key with

```bash
gpg> save
```

#### Creating the Sub Keys

Now that we have our master key, we will create 3 subkeys for each Yubikey you own. Each key will have a special use for encryption, signing and authenticating.



- create sub keys
- add more identities
- export your master
- export your public

### Move the keys to the Yubikey


#### Installing Dependencies

```
sudo apt install pcscd scdaemon
```

#### Trust Model and Agent Restart

```
mkdir ~/.gnupg
cat > ~/.gnupg/scdaemon.conf <<'EOF'
disable-ccid
pcsc-driver /usr/lib/x86_64-linux-gnu/libpcsclite.so.1
card-timeout 1

# Always try to use yubikey as the first reader
# even when other smart card readers are connected
# Name of the reader can be found using the pcsc_scan command
# If you have problems with gpg not recognizing the Yubikey
# then make sure that the string here matches exacly pcsc_scan
# command output. Also check journalctl -f for errors.
reader-port Yubico YubiKey
EOF
```

Enabling trust first use:

```
cat > ~/.gnupg/gpg.conf <<'EOF'
trust-model tofu+pgp
EOF
```

Restart gpg agent

```
systemctl --user restart gpg-agent.service
```

#### Preparing the card

```bash
gpg --card-edit
```

```
gpg/card> admin
Admin commands are allowed

gpg/card> passwd
gpg: OpenPGP card no. D2760001240102010006055532110000 detected

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 3
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 1
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? q
```

Other commands:

```bash
name, lang, login, sex, url
```

#### Transferring the Keys

```bash
gpg --edit-key $KEY
```


Ensure apt transport https.

```
sudo add-apt-repository ppa:yubico/stable && sudo apt-get update
```


### Trust in another machine

```
gpg --fetch-keys URL
```

Check the key

```
gpg --card-status
```

Finally, trust the key ultimately:

```
gpg --edit-key <KEYID>
> trust
# select trust ultimately
```


## Sign commits

```
git config --global user.signingkey <SIGNING KEY ID>
git config --global commit.gpgsign true
```

## SSH Agent

```bash
gpg --armor --export-ssh-key mnavarrocarter@gmail.com > ~/Documents/mnavarro.ssh.pub
```


[udev]: https://opensource.com/article/18/11/udev
[u2f]: https://en.wikipedia.org/wiki/Universal_2nd_Factor
[pam]: https://tldp.org/HOWTO/User-Authentication-HOWTO/x115.html
[facial-pam]: https://github.com/devinaconley/pam-facial-auth
[oss-malware]: https://hackaday.com/2018/10/31/when-good-software-goes-bad-malware-in-open-source/