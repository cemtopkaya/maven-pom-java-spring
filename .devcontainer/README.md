# Docker Installation On Mac

## Setting Up Docker with Colima on macOS

To create a virtual machine for Docker using Colima on macOS, follow these steps:

### 1. Install Colima

First, install [Colima](https://github.com/abiosoft/colima) using Homebrew:

```sh
brew install colima
```

### 2. Configure Colima

Create or edit the `default.yml` configuration file in `~/.colima/` to specify your desired resources:

- **CPU:** 6 cores
- **Memory:** 8GB
- **Swap:** 4GB

Example `~/.colima/default.yml`:

```yaml
cpu: 6
memory: 8
swap: 4
```

### 3. Start Colima

Start Colima with Docker support:

```sh
colima start
```

Colima will use the configuration specified in `default.yml` to allocate resources for the VM.

### 4. Install Docker CLI

If you don't have Docker CLI installed, you can install it via Homebrew:

```sh
brew install docker
```

Now you can use Docker as usual on your Mac, backed by the Colima VM.

---

# Dev Container Overview

## Services

This dev container setup provides the following services via Docker Compose:

- **react_devcontainer**:  
  - Custom Node.js-based development environment for React projects.
  - Built from the provided `Dockerfile`.
  - Includes tools such as Vite, SonarQube Scanner, and Dotenv installed globally.
  - Java Runtime Environment (JRE) is installed for SonarQube IDE integration.
  - Mounts the project workspace for live development.
  - Uses the `devnet` Docker network with a static IP.

- **sonar**:  
  - Runs SonarQube Community Edition for code quality and static analysis.
  - Exposes port `9000` on host port `34000`.
  - Connected to the same `devnet` network with a static IP.

- **nexus**:
  - Repository for jar,war,zip,container image, npm etc.
  - Read the admin password from nexus container (`docker exec -it nexus cat /nexus-data/admin.password`).
  - Exposes port `8081` on host port `8081`.
  - Using browser you can login to the nexus web app.

## devcontainer.json Details

- **Name**: React Dev Container
- **Docker Compose File**: Uses `docker-compose.yml` to orchestrate services.
- **Service**: The main development container is `react_devcontainer`.
- **VS Code Customizations**:
  - Installs recommended extensions for React, linting, formatting, testing, and SonarLint integration.
  - Sets default terminal to bash and default formatter to Prettier.
  - Configures SonarLint for Java and Node.js paths.
  - Example SonarLint server and project configuration is provided (commented out).
- **Ports**: Forwards port `5173` for Vite development server.
- **Workspace Mount**: The parent directory is mounted into `/workspace` inside the container.
- **extensions**: Extensions can be installed by `devcontainer.json` online or offline. If the preferred way installing offline there will be needed to comment `devcontainer.json` file's extension lines (customization->vscode->extensions will run before the `postCreateCommand`). [This url](https://marketplace.visualstudio.com/_apis/public/gallery/publishers/GitHub/vsextensions/copilot/1.320.1565/vspackage
) can be used to download the vsix file.

---

# Configuring SonarQube

When you first access the SonarQube web interface, you will be prompted to change the default password for the `admin` user from `admin` to a new, secure password.

Follow these steps:

- **Create a User Token**
  - Click your username in the top right corner.
  - Select **My Account** from the dropdown menu.
  - In the window that appears, go to the *Security* tab and generate a *User Token*.

- **Create a New Quality Profile**
  - Navigate to [http://localhost:34000/profiles?language=ts](http://localhost:34000/profiles?language=ts).
  - Filter by the `TypeScript` language, click the three-dot menu next to *Sonar Way*, and select **Copy** to create a new profile. Assign a name to your new profile.
  - In your new profile, activate the rule: "Standard outputs should not be used directly to log anything."

- **Create a New Project**
  - Go to [http://localhost:34000/projects](http://localhost:34000/projects) and create a new **Local project**.
    - Enter a **Project display name** and a **Project key**.
    - Click *Next* and select **Reference branch** as the *new code* strategy.
    - Click *Create Project* to complete the process.

- **Assign the Quality Profile to the Project**
  - Go to the Projects page and click on your project's name.
  - Under the *Project Settings* menu, select **Quality Profiles**.
  - For the *TypeScript* language, assign the quality profile you just created.

Once your VS Code and the *SonarQube for IDE* extension are properly configured, rules will be fetched in the background and your code will be validated, with messages displayed directly in your editor.

---

# Creating React App

To create a new React app using Vite, follow these steps for both JavaScript and TypeScript setups, and configure testing with Vitest in a separate config file.

## 1. Create a React App with Vite

### For JavaScript

```sh
npm create vite@latest my-react-app -- --template react
cd my-react-app
```

### For TypeScript

```sh
npm create vite@latest my-react-ts-app -- --template react-ts
cd my-react-ts-app
```

## 2. Install Dependencies

Install project dependencies:

```sh
npm install
```

## 3. Add Vitest for Testing

Install Vitest, React Testing Library, and related types:

```sh
npm install --save-dev vitest \
                       @testing-library/react \
                       @testing-library/jest-dom \
                       @testing-library/user-event
```

## 4. Configure Vitest in a Separate File

Create a `vitest.config.ts` (or `.js` for JS projects) in your project root:

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/setupTests.ts', // or .js for JS projects
    coverage: {
      reporter: ['text', 'json', 'html'],
    },
  },
});
```

Create a setup file for test utilities (optional):

```ts
// src/setupTests.ts
import '@testing-library/jest-dom';
```

## 5. Add Test Script

Update your `package.json`:

```json
"scripts": {
  "test": "vitest"
}
```

Now you can run your tests with:

```sh
npm test
```

---

# Configuring Sonarlint Extension
Click the *SonarQube for IDE* extension. You will see the following tabs:

- Rules
- Connected Mode
- Security Hotspots
- Help and feedback

In the *Connected Mode* tab, click the '+' button and select *Connect to SonarQube Server*. In the window that appears, enter the SonarQube server address and the *User Token* you created earlier, give this connection a name, and save it. You can check whether the connection was successful by observing the Output panel using SonarQube for IDE.

After defining your SonarQube server, you will link the project you previously created in SonarQube to the root directory of your existing code. This will allow you to receive validation results directly within VS Code.