# EthSnarks

This is a collection of zkSNARK circuits and libraries to use them with Ethereum smart contracts.

It aims to:

 * support creating proofs using 'common-spec' smart phones
 * be very easy for developers to integrate into their projects
 * be easily auditable, have comprehensive code coverage and automagic tests
 * support a wide variety of use cases, flexibly

## Building

[![Build Status](https://travis-ci.org/HarryR/ethsnarks.svg?branch=master)](https://travis-ci.org/HarryR/ethsnarks) [![Codacy Badge](https://api.codacy.com/project/badge/Grade/137909bd889347728818d0aa5570fa9a)](https://www.codacy.com/project/HarryR/ethsnarks/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=HarryR/ethsnarks&amp;utm_campaign=Badge_Grade_Dashboard) [![BCH compliance](https://bettercodehub.com/edge/badge/HarryR/ethsnarks?branch=master)](https://bettercodehub.com/)

Type `make` - the first time you run it will retrieve submodules, setup cmake and build everything, for more information about the build process see the Travis logs.

The following dependencies (for Linux) are needed:

 * GNU make
 * cmake
 * g++ or clang++
 * gmp
 * boost
 * npm / nvm

# Requests

This project aims to help create an ecosystem where a small number of well tested but simple zkSNARK circuits can be easily integrated into your project without having to do all of the work up-front.

If you have any ideas for new components, please file a ticket.

# Gadgets

 * 1-of-N
 * MiMC / LongsightL
 * Miyaguchi-Preneel construct
 * SHA256 (full round)
 * Shamir's Secret Sharing Scheme (generation)

# Components

## SHA256 hash preimage

This circuit allows you to prove that you know the preimage for a hash, without revealing the preimage.

### Circuit pseudo-code

 * `root` public - Merkle tree root
 * `path` secret - Merkle proof
 * `preimage_alpha` public - Alice's pre-image for the leaf (uniqueness tag)
 * `preimage_beta` secret - Bob's pre-image for the leaf

```python
def hashpreimage(preimage, expected):
	return SHA256(preimage) == expected
```

# Work-in-progress Components / Ideas

## Unique Merkle Proof

This circuit implements a generic mechanism of proving ownership of an unobservable item within a merkle tree while ensuring that any proof made twice can be identified.

Every leaf of the merkle tree consists of two components:

 * `alpha` - public
 * `beta` - secret

The leaf is `HASH(alpha, HASH(beta))`, this commitment scheme is flexible as two parties can agree on the value of a leaf in private without revealing enough information for one side to create a proof. e.g. Alice creates a random salt for `alpha`, Bob provides the image of `beta`, Alice shows that `leaf = HASH(alpha, beta_image)` but she can't create a proof without knowing `beta` which only Bob does.

Because `alpha` is public at the time of verification the observer can prevent the proof from being accepted twice, however it remains impossible to link that proof back to any leaf in the tree without also knowing the preimage `beta`.

### Circuit pseudo-code

 * `root` public - Merkle tree root
 * `path` secret - Merkle proof
 * `preimage_alpha` public - Alice's pre-image for the leaf (uniqueness tag)
 * `preimage_beta` secret - Bob's pre-image for the leaf
 * `args` public - Any other arguments bound to the proof

```python
def circuit(root, path, preimage_alpha, preimage_beta, args):
	leaf = HASH(preimage_alpha, HASH(preimage_beta))
	return root == merkle_prove(leaf, path)
```

## Linkable Merkle Proof

This circuit allows for the same leaf in the merkle tree to be proven multiple times without revealing it, however any two proofs with the same `public_args_hashed` will be observable as being the same.

### Circuit pseudo-code

 * `root` public - Merkle tree root
 * `path` secret - Merkle proof
 * `tag` public - Unique tag for the proof
 * `unique_args` public - Arguments for the unique tag
 * `preimage` secret - Pre-image for the leaf / tag
 * `args` public - Any other arguments bound to the proof

```python
def circuit(root, path, tag, unique_args, preimage, args):
	leaf = HASH(preimage)
	path_ok = root == merkle_prove(leaf, path)
	tag_ok = tag == HASH(preimage, unique_args)
	return path_ok and tag_ok
```
