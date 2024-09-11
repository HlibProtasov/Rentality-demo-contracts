import { useAppContext } from "@/contexts/appContext";
import HeaderLogo from "./headerLogo";

export default function BaseBurgerNavMenu({ children }: { children?: React.ReactNode }) {
  const { closeBurgerMenu } = useAppContext();

  const handleOnClick = () => {
    closeBurgerMenu();
  };

  return (
    <div className="pl-14 pr-12 pt-8">
      <HeaderLogo onClick={handleOnClick} />
      <nav className="mb-44 w-full pt-4">{children}</nav>
    </div>
  );
}
